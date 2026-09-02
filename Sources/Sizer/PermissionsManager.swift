import AppKit
import ApplicationServices

/// Handles the Accessibility permission the app needs to move other apps'
/// windows. Prompts on first launch, then — because `AXIsProcessTrusted()` is
/// cached per-process and does NOT flip live when the user toggles the
/// permission — relaunches the app once the grant is detected so the new
/// process starts up trusted.
final class PermissionsManager {
    /// Called (on the main thread) once the process is trusted.
    var onTrusted: (() -> Void)?

    private var pollTimer: Timer?
    private var changeObserver: NSObjectProtocol?
    private var didRelaunch = false

    var isTrusted: Bool { AXIsProcessTrusted() }

    func requestIfNeeded() {
        if isTrusted {
            onTrusted?()
            return
        }
        // Shows the system dialog with a deep link to
        // System Settings > Privacy & Security > Accessibility.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        observeAccessibilityChanges()
        startPolling()
    }

    /// macOS posts this distributed notification when any app's Accessibility
    /// authorization changes.
    private func observeAccessibilityChanges() {
        changeObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Give TCC a moment to settle after the toggle.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self?.handleChange() }
        }
    }

    private func handleChange() {
        if isTrusted {
            onTrusted?()
            return
        }
        // Trust didn't update in-process (the common case). Relaunch once so a
        // fresh process picks up the new permission.
        guard !didRelaunch else { return }
        didRelaunch = true
        Log.event("Accessibility changed while untrusted; relaunching to apply it")
        relaunch()
    }

    private func relaunch() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundlePath]
        try? task.run()
        NSApp.terminate(nil)
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            if self.isTrusted {
                timer.invalidate()
                self.pollTimer = nil
                self.onTrusted?()
            }
        }
    }
}
