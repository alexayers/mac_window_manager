import AppKit

/// Display geometry queries. All rectangles returned here are in AppKit
/// (bottom-left origin) space; convert with `CoordinateConverter` before handing
/// them to the Accessibility API.
enum ScreenManager {
    /// Screens ordered left-to-right then bottom-to-top, for stable
    /// next/previous-display cycling.
    static func orderedScreens() -> [NSScreen] {
        NSScreen.screens.sorted {
            if $0.frame.minX != $1.frame.minX { return $0.frame.minX < $1.frame.minX }
            return $0.frame.minY < $1.frame.minY
        }
    }

    /// The screen whose full frame contains `point` (an AppKit point, typically
    /// a window's center). Falls back to the main screen.
    static func screen(containing point: CGPoint) -> NSScreen {
        for screen in NSScreen.screens where screen.frame.contains(point) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    /// `visibleFrame` (already excludes the menu bar and Dock) inset by an
    /// optional screen-edge gap.
    static func usableFrame(of screen: NSScreen, gap: CGFloat) -> CGRect {
        guard gap > 0 else { return screen.visibleFrame }
        return screen.visibleFrame.insetBy(dx: gap, dy: gap)
    }
}
