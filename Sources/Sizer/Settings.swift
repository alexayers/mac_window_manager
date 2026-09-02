import Foundation

/// UserDefaults-backed tunables shared by the executor and the preferences UI.
enum Settings {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let screenEdgeGap = "screenEdgeGap"
        static let moveStep = "moveStep"
        static let resizeStep = "resizeStep"
    }

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.screenEdgeGap: 0,
            Key.moveStep: 60,
            Key.resizeStep: 60,
        ])
    }

    /// Inset applied to every screen's usable area (SizeUp "screen edge" gap).
    static var screenEdgeGap: CGFloat {
        get { CGFloat(defaults.integer(forKey: Key.screenEdgeGap)) }
        set { defaults.set(Int(newValue), forKey: Key.screenEdgeGap) }
    }

    /// Distance a nudge moves the window, in points.
    static var moveStep: CGFloat {
        get { CGFloat(defaults.integer(forKey: Key.moveStep)) }
        set { defaults.set(Int(newValue), forKey: Key.moveStep) }
    }

    /// Amount grow/shrink changes a dimension, in points.
    static var resizeStep: CGFloat {
        get { CGFloat(defaults.integer(forKey: Key.resizeStep)) }
        set { defaults.set(Int(newValue), forKey: Key.resizeStep) }
    }
}
