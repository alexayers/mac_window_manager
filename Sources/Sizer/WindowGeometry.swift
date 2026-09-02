import CoreGraphics

/// Pure, screen-independent window geometry. All rectangles are in AppKit
/// (bottom-left origin) space. Kept free of AppKit/Accessibility/Settings so it
/// can be unit-tested headlessly (see `SelfTest`).
enum WindowGeometry {
    static let minSize: CGFloat = 120

    /// Target frame for an action within `area` (a screen's usable frame).
    /// Returns nil for actions that need multi-display context
    /// (`nextDisplay`/`previousDisplay`) or are handled elsewhere (`snapBack`).
    static func target(for action: WindowAction,
                       current: CGRect,
                       area: CGRect,
                       moveStep: CGFloat,
                       resizeStep: CGFloat) -> CGRect? {
        let w = area.width, h = area.height
        switch action {
        // Halves
        case .leftHalf:   return CGRect(x: area.minX, y: area.minY, width: w / 2, height: h)
        case .rightHalf:  return CGRect(x: area.midX, y: area.minY, width: w / 2, height: h)
        case .topHalf:    return CGRect(x: area.minX, y: area.midY, width: w, height: h / 2)
        case .bottomHalf: return CGRect(x: area.minX, y: area.minY, width: w, height: h / 2)

        // Quarters
        case .topLeft:     return CGRect(x: area.minX, y: area.midY, width: w / 2, height: h / 2)
        case .topRight:    return CGRect(x: area.midX, y: area.midY, width: w / 2, height: h / 2)
        case .bottomLeft:  return CGRect(x: area.minX, y: area.minY, width: w / 2, height: h / 2)
        case .bottomRight: return CGRect(x: area.midX, y: area.minY, width: w / 2, height: h / 2)

        // Thirds (vertical columns)
        case .leftThird:      return CGRect(x: area.minX,             y: area.minY, width: w / 3,     height: h)
        case .centerThird:    return CGRect(x: area.minX + w / 3,     y: area.minY, width: w / 3,     height: h)
        case .rightThird:     return CGRect(x: area.minX + 2 * w / 3, y: area.minY, width: w / 3,     height: h)
        case .leftTwoThirds:  return CGRect(x: area.minX,             y: area.minY, width: 2 * w / 3, height: h)
        case .rightTwoThirds: return CGRect(x: area.minX + w / 3,     y: area.minY, width: 2 * w / 3, height: h)

        // Size
        case .maximize:
            return area
        case .center:
            let cw = min(current.width, w), ch = min(current.height, h)
            return CGRect(x: area.midX - cw / 2, y: area.midY - ch / 2, width: cw, height: ch)

        // Move (AppKit: up is +y)
        case .nudgeLeft:  return current.offsetBy(dx: -moveStep, dy: 0)
        case .nudgeRight: return current.offsetBy(dx:  moveStep, dy: 0)
        case .nudgeUp:    return current.offsetBy(dx: 0, dy:  moveStep)
        case .nudgeDown:  return current.offsetBy(dx: 0, dy: -moveStep)

        // Resize, keeping the visual top-left corner fixed
        case .growWidth:    return resized(current, dw:  resizeStep, dh: 0)
        case .shrinkWidth:  return resized(current, dw: -resizeStep, dh: 0)
        case .growHeight:   return resized(current, dw: 0, dh:  resizeStep)
        case .shrinkHeight: return resized(current, dw: 0, dh: -resizeStep)

        // Needs multi-display context / handled elsewhere
        case .nextDisplay, .previousDisplay, .snapBack:
            return nil
        }
    }

    /// Resize by (dw, dh) while keeping the window's on-screen top-left corner
    /// fixed. In AppKit the top edge is `maxY`, so growing height lowers the
    /// origin's Y.
    static func resized(_ frame: CGRect, dw: CGFloat, dh: CGFloat) -> CGRect {
        let topLeft = CGPoint(x: frame.minX, y: frame.maxY)
        let newWidth = max(frame.width + dw, minSize)
        let newHeight = max(frame.height + dh, minSize)
        return CGRect(x: topLeft.x, y: topLeft.y - newHeight, width: newWidth, height: newHeight)
    }
}
