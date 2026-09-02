import AppKit
import Carbon.HIToolbox

/// A global hotkey: a hardware key code plus Carbon modifier flags
/// (cmdKey / optionKey / controlKey / shiftKey). `keyCode` matches both
/// Carbon's `kVK_*` constants and `NSEvent.keyCode`, so the same value works
/// for `RegisterEventHotKey` and for capturing key events in the recorder.
struct Shortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    /// Human-readable form, e.g. "⌃⌥⌘←".
    var displayString: String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { s += "⌘" }
        s += KeyCodeMap.label(for: keyCode)
        return s
    }

    /// The single-character key equivalent used to display this shortcut in an
    /// `NSMenuItem` (arrows map to function-key unicode).
    var menuKeyEquivalent: String { KeyCodeMap.menuEquivalent(for: keyCode) }

    /// AppKit modifier flags for `NSMenuItem.keyEquivalentModifierMask`.
    var modifierFlags: NSEvent.ModifierFlags { CarbonModifiers.toNSFlags(modifiers) }
}

/// Conversion between AppKit `NSEvent.ModifierFlags` and Carbon modifier masks.
enum CarbonModifiers {
    static func from(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command) { m |= UInt32(cmdKey) }
        if flags.contains(.option)  { m |= UInt32(optionKey) }
        if flags.contains(.control) { m |= UInt32(controlKey) }
        if flags.contains(.shift)   { m |= UInt32(shiftKey) }
        return m
    }

    static func toNSFlags(_ m: UInt32) -> NSEvent.ModifierFlags {
        var f: NSEvent.ModifierFlags = []
        if m & UInt32(cmdKey) != 0     { f.insert(.command) }
        if m & UInt32(optionKey) != 0  { f.insert(.option) }
        if m & UInt32(controlKey) != 0 { f.insert(.control) }
        if m & UInt32(shiftKey) != 0   { f.insert(.shift) }
        return f
    }

    /// A shortcut needs at least one of these to be usable as a global hotkey.
    static func hasModifier(_ m: UInt32) -> Bool {
        m & (UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey)) != 0
    }
}

/// Maps hardware key codes to display labels and menu key equivalents.
enum KeyCodeMap {
    private static let letters: [Int: String] = [
        kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d",
        kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h",
        kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
        kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p",
        kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
        kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
        kVK_ANSI_Y: "y", kVK_ANSI_Z: "z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
    ]

    /// Uppercase / symbol label shown in menus and preferences.
    static func label(for code: UInt32) -> String {
        switch Int(code) {
        case kVK_LeftArrow:  return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow:    return "↑"
        case kVK_DownArrow:  return "↓"
        case kVK_Return:     return "↩"
        case kVK_Space:      return "Space"
        case kVK_Escape:     return "⎋"
        case kVK_Tab:        return "⇥"
        case kVK_Delete:     return "⌫"
        default:
            if let c = letters[Int(code)] { return c.uppercased() }
            return "Key \(code)"
        }
    }

    /// The character `NSMenuItem` uses to render the shortcut on the right side.
    static func menuEquivalent(for code: UInt32) -> String {
        func fnKey(_ v: Int) -> String { String(utf16CodeUnits: [unichar(v)], count: 1) }
        switch Int(code) {
        case kVK_LeftArrow:  return fnKey(NSLeftArrowFunctionKey)
        case kVK_RightArrow: return fnKey(NSRightArrowFunctionKey)
        case kVK_UpArrow:    return fnKey(NSUpArrowFunctionKey)
        case kVK_DownArrow:  return fnKey(NSDownArrowFunctionKey)
        case kVK_Return:     return "\r"
        case kVK_Space:      return " "
        default:
            return letters[Int(code)] ?? ""
        }
    }
}
