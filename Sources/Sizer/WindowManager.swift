import AppKit
import ApplicationServices

/// Executes a `WindowAction` on the focused window. Responsibilities:
/// 1. Fetch the focused window (Accessibility) and its current frame.
/// 2. Locate the screen it lives on and that screen's usable area.
/// 3. Compute the target rectangle in AppKit space.
/// 4. Flip to Accessibility space and apply it.
///
/// All geometry math is done in AppKit space and flipped exactly once, via
/// `CoordinateConverter`, immediately before the window is moved.
final class WindowManager {
    private let snapBack = SnapBackStore()

    func perform(_ action: WindowAction) {
        let trusted = AXIsProcessTrusted()
        Log.event("perform \(action.rawValue); trusted=\(trusted)")

        // Moving other apps' windows requires Accessibility permission. Check it
        // live each time so the app works as soon as the user grants it, and
        // give feedback (prompt + beep) instead of silently doing nothing.
        guard trusted else {
            Log.event("  -> NOT TRUSTED; prompting + beep")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            NSSound.beep()
            return
        }

        guard let window = AccessibilityElement.focusedWindow(),
              let axFrame = window.frame else {
            Log.event("  -> no focused window (frontmost=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"))")
            NSSound.beep()
            return
        }

        // SnapBack: restore and return before any other bookkeeping.
        if action == .snapBack {
            if let restored = snapBack.restore(window: window) {
                window.setFrame(restored)
            } else {
                NSSound.beep()
            }
            return
        }

        // Capture the pre-snap frame (once) so SnapBack can return to it later.
        snapBack.save(window: window, frame: axFrame)

        let appKitFrame = CoordinateConverter.axToAppKit(axFrame)
        let center = CGPoint(x: appKitFrame.midX, y: appKitFrame.midY)
        let screen = ScreenManager.screen(containing: center)
        let area = ScreenManager.usableFrame(of: screen, gap: Settings.screenEdgeGap)

        guard let target = targetFrame(for: action, current: appKitFrame, area: area, screen: screen) else {
            NSSound.beep()
            return
        }

        let axTarget = CoordinateConverter.appKitToAX(target)
        window.setFrame(axTarget)
        let after = window.frame.map { "\(Int($0.minX)),\(Int($0.minY)) \(Int($0.width))x\(Int($0.height))" } ?? "?"
        Log.event("  -> applied \(action.rawValue); frontmost=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"); resultAXframe=\(after)")
    }

    // MARK: - Target computation (all rectangles in AppKit / bottom-left space)

    private func targetFrame(for action: WindowAction,
                             current: CGRect,
                             area: CGRect,
                             screen: NSScreen) -> CGRect? {
        switch action {
        case .nextDisplay:     return moveToAdjacentDisplay(current: current, from: screen, direction: 1)
        case .previousDisplay: return moveToAdjacentDisplay(current: current, from: screen, direction: -1)
        default:
            return WindowGeometry.target(for: action,
                                         current: current,
                                         area: area,
                                         moveStep: Settings.moveStep,
                                         resizeStep: Settings.resizeStep)
        }
    }

    /// Move the window to the next/previous screen (wrapping around, like
    /// SizeUp's "circularize"), preserving its relative position and clamping
    /// its size to fit the destination.
    private func moveToAdjacentDisplay(current: CGRect, from screen: NSScreen, direction: Int) -> CGRect? {
        let screens = ScreenManager.orderedScreens()
        guard screens.count > 1, let idx = screens.firstIndex(of: screen) else { return nil }

        let target = screens[(idx + direction + screens.count) % screens.count]
        let source = ScreenManager.usableFrame(of: screen, gap: Settings.screenEdgeGap)
        let dest = ScreenManager.usableFrame(of: target, gap: Settings.screenEdgeGap)

        let relX = (current.minX - source.minX) / max(source.width, 1)
        let relY = (current.minY - source.minY) / max(source.height, 1)

        let newW = min(current.width, dest.width)
        let newH = min(current.height, dest.height)
        var newX = dest.minX + relX * dest.width
        var newY = dest.minY + relY * dest.height

        // Keep the window fully on the destination screen.
        newX = min(max(newX, dest.minX), dest.maxX - newW)
        newY = min(max(newY, dest.minY), dest.maxY - newH)

        return CGRect(x: newX, y: newY, width: newW, height: newH)
    }
}
