import AppKit

// Headless verification of the coordinate math and hotkey registration.
// Runs without the status bar or Accessibility, then exits.
if CommandLine.arguments.contains("--selftest") {
    exit(SelfTest.run() ? 0 : 1)
}

// Headless single action against the current frontmost window, then exit. Uses
// the same signed bundle identity as the menu-bar app, so it shares its
// Accessibility grant. Diagnostics go to /tmp/sizer.log.
if let idx = CommandLine.arguments.firstIndex(of: "--perform"),
   idx + 1 < CommandLine.arguments.count {
    let raw = CommandLine.arguments[idx + 1]
    guard let action = WindowAction(rawValue: raw) else {
        Log.file("--perform: unknown action '\(raw)'")
        exit(2)
    }
    Log.file("--perform \(raw): starting; trusted=\(AXIsProcessTrusted())")
    WindowManager().perform(action)
    exit(0)
}

// Agent app: lives in the menu bar, no Dock icon (also set via LSUIElement).
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
