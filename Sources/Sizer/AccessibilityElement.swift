import AppKit
import ApplicationServices

/// Thin wrapper over an `AXUIElement` representing a window, exposing typed
/// position/size access. All frames here are in Accessibility (top-left origin)
/// space.
final class AccessibilityElement {
    let rawElement: AXUIElement

    init(_ element: AXUIElement) {
        self.rawElement = element
    }

    /// The focused window of the frontmost application, or its first window as a
    /// fallback. Returns nil if nothing suitable is found (or permission is
    /// missing).
    static func focusedWindow() -> AccessibilityElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var focused: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focused) == .success,
           let focused {
            return AccessibilityElement(focused as! AXUIElement)
        }

        var windows: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success,
           let list = windows as? [AXUIElement], let first = list.first {
            return AccessibilityElement(first)
        }
        return nil
    }

    var position: CGPoint? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(rawElement, kAXPositionAttribute as CFString, &ref) == .success,
              let ref else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(ref as! AXValue, .cgPoint, &point)
        return point
    }

    var size: CGSize? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(rawElement, kAXSizeAttribute as CFString, &ref) == .success,
              let ref else { return nil }
        var size = CGSize.zero
        AXValueGetValue(ref as! AXValue, .cgSize, &size)
        return size
    }

    /// Current window frame in Accessibility (top-left origin) space.
    var frame: CGRect? {
        guard let position, let size else { return nil }
        return CGRect(origin: position, size: size)
    }

    func setPosition(_ point: CGPoint) {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return }
        AXUIElementSetAttributeValue(rawElement, kAXPositionAttribute as CFString, value)
    }

    func setSize(_ size: CGSize) {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return }
        AXUIElementSetAttributeValue(rawElement, kAXSizeAttribute as CFString, value)
    }

    /// Apply an Accessibility-space frame using the size → position → size
    /// sequence. macOS clamps a window's size to fit its *current* display
    /// before the position moves, so a naive position-then-size leaves
    /// cross-display moves the wrong size; the trailing `setSize` corrects it.
    func setFrame(_ axFrame: CGRect) {
        setSize(axFrame.size)
        setPosition(axFrame.origin)
        setSize(axFrame.size)
    }
}
