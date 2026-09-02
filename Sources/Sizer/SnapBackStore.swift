import AppKit
import ApplicationServices

/// Remembers each window's frame from *before* it was first snapped, so
/// `.snapBack` can restore it. Frames are stored in Accessibility space.
///
/// The original frame is captured only once per window (repeated snaps keep the
/// pre-snap frame) and consumed on restore, so the next snap re-captures.
final class SnapBackStore {
    private struct Entry {
        let element: AXUIElement
        let frame: CGRect
    }

    private var entries: [Entry] = []
    private let maxEntries = 40

    /// Record the window's frame if we don't already have one for it.
    func save(window: AccessibilityElement, frame: CGRect) {
        guard index(of: window.rawElement) == nil else { return }
        entries.append(Entry(element: window.rawElement, frame: frame))
        if entries.count > maxEntries { entries.removeFirst() }
    }

    /// Return and consume the stored frame for this window, if any.
    func restore(window: AccessibilityElement) -> CGRect? {
        guard let i = index(of: window.rawElement) else { return nil }
        let frame = entries[i].frame
        entries.remove(at: i)
        return frame
    }

    private func index(of element: AXUIElement) -> Int? {
        entries.firstIndex { CFEqual($0.element, element) }
    }
}
