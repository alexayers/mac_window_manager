import Foundation

/// The user's `WindowAction → Shortcut` bindings, persisted as JSON in
/// UserDefaults. Seeds SizeUp's defaults on first run.
final class ShortcutStore {
    private static let key = "shortcutBindings"

    private(set) var bindings: [WindowAction: Shortcut]

    init() {
        bindings = ShortcutStore.load() ?? WindowAction.defaultBindings()
    }

    /// Assign (or clear, with nil) a shortcut for an action. Any *other* action
    /// currently using the same shortcut is cleared first, so a chord is never
    /// bound to two actions at once (which would fail to register).
    func set(_ shortcut: Shortcut?, for action: WindowAction) {
        if let shortcut {
            for (other, existing) in bindings where other != action && existing == shortcut {
                bindings.removeValue(forKey: other)
            }
            bindings[action] = shortcut
        } else {
            bindings.removeValue(forKey: action)
        }
        save()
    }

    func resetToDefaults() {
        bindings = WindowAction.defaultBindings()
        save()
    }

    private func save() {
        let raw = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(raw) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private static func load() -> [WindowAction: Shortcut]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let raw = try? JSONDecoder().decode([String: Shortcut].self, from: data) else {
            return nil
        }
        var result: [WindowAction: Shortcut] = [:]
        for (rawAction, shortcut) in raw {
            if let action = WindowAction(rawValue: rawAction) {
                result[action] = shortcut
            }
        }
        return result
    }
}
