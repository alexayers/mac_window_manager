import Foundation
import os

/// Logging with two sinks:
/// - `os.Logger` for Console.app / `log show`.
/// - a plain text file at `/tmp/sizer.log` that is always readable regardless of
///   unified-logging quirks — used for diagnostics during development.
enum Log {
    static let general = Logger(subsystem: "com.diskrot.Sizer", category: "general")

    private static let fileURL = URL(fileURLWithPath: "/tmp/sizer.log")

    /// Log to both the unified log and the diagnostics file.
    static func event(_ message: String) {
        general.notice("\(message, privacy: .public)")
        file(message)
    }

    static func file(_ message: String) {
        let line = "\(timestamp()) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(data)
        } else {
            try? data.write(to: fileURL)
        }
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}
