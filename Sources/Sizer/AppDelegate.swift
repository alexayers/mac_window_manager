import AppKit

/// Builds the object graph and wires hotkeys + menu to the executor.
///
/// Global hotkeys are registered immediately at launch — Carbon hotkeys do NOT
/// require Accessibility permission. Only *moving* a window does, so the
/// permission is checked (with feedback) at action time in `WindowManager`.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissions = PermissionsManager()
    private let windowManager = WindowManager()
    private let hotKeys = HotKeyManager()
    private let shortcuts = ShortcutStore()
    private var menuBar: MenuBarController!
    private var preferences: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Settings.registerDefaults()

        Log.event("launched; trusted=\(AXIsProcessTrusted())")

        menuBar = MenuBarController()
        menuBar.onAction = { [weak self] action in self?.windowManager.perform(action) }
        menuBar.onPreferences = { [weak self] in self?.openPreferences() }
        menuBar.refresh(bindings: shortcuts.bindings)

        hotKeys.onAction = { [weak self] action in self?.windowManager.perform(action) }
        reloadHotKeys() // register now, independent of Accessibility permission

        permissions.onTrusted = { Log.event("Accessibility permission granted (poll detected trusted=true).") }
        permissions.requestIfNeeded()
    }

    private func reloadHotKeys() {
        hotKeys.register(shortcuts.bindings)
    }

    private func openPreferences() {
        if preferences == nil {
            preferences = PreferencesWindowController(shortcuts: shortcuts) { [weak self] in
                guard let self else { return }
                self.reloadHotKeys()
                self.menuBar.refresh(bindings: self.shortcuts.bindings)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
        preferences?.showWindow(nil)
    }
}
