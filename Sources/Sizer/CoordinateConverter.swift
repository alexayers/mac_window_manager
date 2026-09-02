import AppKit

/// Single source of truth for converting rectangles between the two coordinate
/// systems in play:
///
/// - **AppKit / NSScreen**: origin bottom-left, Y increases upward.
/// - **Accessibility (kAXPosition)**: origin top-left, Y increases downward,
///   anchored to the primary (menu-bar) screen.
///
/// The transform is its own inverse (it uses `maxY`), so one formula covers both
/// directions. `primaryHeight` must be the *full* frame height of the primary
/// screen — never a `visibleFrame` — and is read fresh each call because the
/// display arrangement can change at runtime.
enum CoordinateConverter {
    static var primaryHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    static func flip(_ rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: rect.minX,
               y: primaryHeight - rect.maxY,
               width: rect.width,
               height: rect.height)
    }

    /// AppKit (bottom-left) → Accessibility (top-left).
    static func appKitToAX(_ rect: CGRect) -> CGRect {
        flip(rect, primaryHeight: primaryHeight)
    }

    /// Accessibility (top-left) → AppKit (bottom-left).
    static func axToAppKit(_ rect: CGRect) -> CGRect {
        flip(rect, primaryHeight: primaryHeight)
    }
}
