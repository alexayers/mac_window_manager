import AppKit
import ApplicationServices

/// Owns the menu bar status item and its menu. Each action item carries its
/// `WindowAction` in `representedObject`; selecting it calls `onAction`.
///
/// The menu is rebuilt from scratch on every refresh, so all items are created
/// fresh each time — an `NSMenuItem` can belong to only one menu, and reusing a
/// stored instance across rebuilds throws "already associated with a menu".
final class MenuBarController: NSObject, NSMenuDelegate {
    var onAction: ((WindowAction) -> Void)?
    var onPreferences: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var bindings: [WindowAction: Shortcut] = [:]

    // References into the *current* menu, refreshed on each rebuild, so the
    // permission banner can be updated when the menu opens.
    private weak var permissionItem: NSMenuItem?
    private weak var permissionSeparator: NSMenuItem?

    override init() {
        super.init()
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.split.2x1",
                                   accessibilityDescription: "Sizer")
            button.image?.isTemplate = true
        }
        rebuildMenu()
    }

    /// Update the shortcut hints shown next to each item.
    func refresh(bindings: [WindowAction: Shortcut]) {
        self.bindings = bindings
        rebuildMenu()
    }

    /// Refresh the permission banner whenever the menu is about to open.
    func menuWillOpen(_ menu: NSMenu) {
        updatePermissionItem()
    }

    private func updatePermissionItem() {
        let trusted = AXIsProcessTrusted()
        permissionItem?.isHidden = trusted
        permissionSeparator?.isHidden = trusted
        if !trusted, let item = permissionItem {
            item.title = "⚠️ Enable Accessibility Access…"
            item.target = self
            item.action = #selector(openAccessibilitySettings)
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        // Permission banner (shown only when Accessibility is not yet granted).
        let permItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let permSep = NSMenuItem.separator()
        permissionItem = permItem
        permissionSeparator = permSep
        menu.addItem(permItem)
        menu.addItem(permSep)
        updatePermissionItem()

        for group in ActionGroup.allCases {
            let header = NSMenuItem(title: group.rawValue, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
            for action in group.actions {
                menu.addItem(makeItem(for: action))
            }
            menu.addItem(.separator())
        }

        let prefs = NSMenuItem(title: "Preferences…",
                               action: #selector(preferencesClicked),
                               keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let quit = NSMenuItem(title: "Quit Sizer",
                              action: #selector(quitClicked),
                              keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func makeItem(for action: WindowAction) -> NSMenuItem {
        let item = NSMenuItem(title: action.title,
                              action: #selector(actionClicked(_:)),
                              keyEquivalent: "")
        item.target = self
        item.representedObject = action.rawValue
        // Key equivalents here are display hints; they only fire while this menu
        // is open, so they don't clash with the global Carbon hotkeys.
        if let shortcut = bindings[action] {
            item.keyEquivalent = shortcut.menuKeyEquivalent
            item.keyEquivalentModifierMask = shortcut.modifierFlags
        }
        return item
    }

    @objc private func actionClicked(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let action = WindowAction(rawValue: raw) else { return }
        onAction?(action)
    }

    @objc private func preferencesClicked() {
        onPreferences?()
    }

    @objc private func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
