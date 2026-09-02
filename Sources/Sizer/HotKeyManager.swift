import AppKit
import Carbon.HIToolbox

/// Registers system-wide hotkeys with Carbon's `RegisterEventHotKey` — the only
/// public API for global hotkeys that needs no extra permission. A single
/// event handler dispatches presses back to `onAction` by hotkey id.
final class HotKeyManager {
    var onAction: ((WindowAction) -> Void)?

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var actionForID: [UInt32: WindowAction] = [:]

    /// Number of currently registered hotkeys (used by the self-test).
    var registeredCount: Int { hotKeyRefs.count }

    /// Four-char signature 'WMGR' identifying our hotkeys.
    private static let signature: OSType = {
        "WMGR".utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }()

    /// Replace all registrations with the given bindings. Bindings without at
    /// least one modifier, or that fail to register (e.g. duplicates), are
    /// skipped.
    func register(_ bindings: [WindowAction: Shortcut]) {
        unregisterAll()
        installHandlerIfNeeded()

        var nextID: UInt32 = 1
        for (action, shortcut) in bindings {
            guard CarbonModifiers.hasModifier(shortcut.modifiers) else { continue }
            var ref: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: nextID)
            let status = RegisterEventHotKey(shortcut.keyCode,
                                             shortcut.modifiers,
                                             hotKeyID,
                                             GetEventDispatcherTarget(),
                                             0,
                                             &ref)
            if status == noErr {
                actionForID[nextID] = action
                hotKeyRefs.append(ref)
                nextID += 1
                Log.file("  register OK \(action.rawValue) keyCode=\(shortcut.keyCode) mods=\(shortcut.modifiers)")
            } else {
                Log.file("  register FAIL \(action.rawValue) keyCode=\(shortcut.keyCode) mods=\(shortcut.modifiers) status=\(status)")
            }
        }
        Log.event("registered \(hotKeyRefs.count)/\(bindings.count) hotkeys")
    }

    /// Called by the Carbon handler on every hotkey press (before dispatch).
    fileprivate func logIncoming(id: UInt32) {
        Log.file("hotkey event id=\(id) action=\(actionForID[id]?.rawValue ?? "none")")
    }

    func unregisterAll() {
        for ref in hotKeyRefs where ref != nil {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        actionForID.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(event,
                                            EventParamName(kEventParamDirectObject),
                                            EventParamType(typeEventHotKeyID),
                                            nil,
                                            MemoryLayout<EventHotKeyID>.size,
                                            nil,
                                            &hotKeyID)
                guard err == noErr else { return err }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.logIncoming(id: hotKeyID.id)
                if let action = manager.actionForID[hotKeyID.id] {
                    DispatchQueue.main.async { manager.onAction?(action) }
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    deinit {
        unregisterAll()
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
