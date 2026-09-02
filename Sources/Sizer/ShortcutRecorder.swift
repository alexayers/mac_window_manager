import AppKit
import Carbon.HIToolbox

/// A button that records a keyboard shortcut. Click it, then press a chord; the
/// captured `Shortcut` is reported via `onCapture`. Escape cancels, Delete/⌫
/// clears the binding (reports nil). A chord must include at least one of
/// Control/Option/Command to be valid as a global hotkey.
final class ShortcutRecorderButton: NSButton {
    var onCapture: ((Shortcut?) -> Void)?

    var shortcut: Shortcut? {
        didSet { updateTitle() }
    }

    private var isRecording = false {
        didSet { updateTitle() }
    }
    private var monitor: Any?

    init() {
        super.init(frame: .zero)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(toggleRecording)
        updateTitle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc private func toggleRecording() {
        isRecording ? stop() : start()
    }

    private func start() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }
            guard event.type == .keyDown else { return nil } // swallow flagsChanged while recording

            switch Int(event.keyCode) {
            case kVK_Escape:
                self.stop()
                return nil
            case kVK_Delete, kVK_ForwardDelete:
                self.shortcut = nil
                self.onCapture?(nil)
                self.stop()
                return nil
            default:
                break
            }

            let modifiers = CarbonModifiers.from(event.modifierFlags)
            guard CarbonModifiers.hasModifier(modifiers) else {
                NSSound.beep() // needs at least one of ⌃⌥⌘
                return nil
            }

            let captured = Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
            self.shortcut = captured
            self.onCapture?(captured)
            self.stop()
            return nil
        }
    }

    private func stop() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func updateTitle() {
        if isRecording {
            title = "Type shortcut…"
        } else if let shortcut {
            title = shortcut.displayString
        } else {
            title = "Record…"
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
