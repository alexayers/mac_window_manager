import Carbon.HIToolbox

/// Every window operation the app can perform. The raw value is the persistence
/// key for a user-configured shortcut, so do not rename cases casually.
enum WindowAction: String, CaseIterable {
    // Halves
    case leftHalf, rightHalf, topHalf, bottomHalf
    // Quarters
    case topLeft, topRight, bottomLeft, bottomRight
    // Thirds (vertical columns)
    case leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds
    // Size
    case maximize, center
    // Move by a step (no resize)
    case nudgeLeft, nudgeRight, nudgeUp, nudgeDown
    // Resize by a step (top-left corner fixed)
    case growWidth, shrinkWidth, growHeight, shrinkHeight
    // Displays
    case nextDisplay, previousDisplay
    // Restore the frame the window had before it was first snapped.
    case snapBack

    var title: String {
        switch self {
        case .leftHalf:       return "Left Half"
        case .rightHalf:      return "Right Half"
        case .topHalf:        return "Top Half"
        case .bottomHalf:     return "Bottom Half"
        case .topLeft:        return "Top Left"
        case .topRight:       return "Top Right"
        case .bottomLeft:     return "Bottom Left"
        case .bottomRight:    return "Bottom Right"
        case .leftThird:      return "Left Third"
        case .centerThird:    return "Center Third"
        case .rightThird:     return "Right Third"
        case .leftTwoThirds:  return "Left Two Thirds"
        case .rightTwoThirds: return "Right Two Thirds"
        case .maximize:       return "Maximize"
        case .center:         return "Center"
        case .nudgeLeft:      return "Move Left"
        case .nudgeRight:     return "Move Right"
        case .nudgeUp:        return "Move Up"
        case .nudgeDown:      return "Move Down"
        case .growWidth:      return "Grow Width"
        case .shrinkWidth:    return "Shrink Width"
        case .growHeight:     return "Grow Height"
        case .shrinkHeight:   return "Shrink Height"
        case .nextDisplay:    return "Move to Next Display"
        case .previousDisplay:return "Move to Previous Display"
        case .snapBack:       return "Snap Back"
        }
    }

    /// SizeUp's classic defaults: ⌃⌥⌘ + arrows / M / C. Other actions ship
    /// unbound and are reachable from the menu until the user assigns a key.
    var defaultShortcut: Shortcut? {
        let ctrlOptCmd = UInt32(controlKey) | UInt32(optionKey) | UInt32(cmdKey)
        switch self {
        case .leftHalf:   return Shortcut(keyCode: UInt32(kVK_LeftArrow),  modifiers: ctrlOptCmd)
        case .rightHalf:  return Shortcut(keyCode: UInt32(kVK_RightArrow), modifiers: ctrlOptCmd)
        case .topHalf:    return Shortcut(keyCode: UInt32(kVK_UpArrow),    modifiers: ctrlOptCmd)
        case .bottomHalf: return Shortcut(keyCode: UInt32(kVK_DownArrow),  modifiers: ctrlOptCmd)
        case .maximize:   return Shortcut(keyCode: UInt32(kVK_ANSI_M),     modifiers: ctrlOptCmd)
        case .center:     return Shortcut(keyCode: UInt32(kVK_ANSI_C),     modifiers: ctrlOptCmd)
        default:          return nil
        }
    }

    static func defaultBindings() -> [WindowAction: Shortcut] {
        var d: [WindowAction: Shortcut] = [:]
        for action in allCases {
            if let s = action.defaultShortcut { d[action] = s }
        }
        return d
    }
}

/// Menu / preferences grouping so both UIs stay in sync.
enum ActionGroup: String, CaseIterable {
    case halves = "Halves"
    case quarters = "Quarters"
    case thirds = "Thirds"
    case size = "Size"
    case move = "Move"
    case resize = "Resize"
    case display = "Display"
    case other = "Other"

    var actions: [WindowAction] {
        switch self {
        case .halves:   return [.leftHalf, .rightHalf, .topHalf, .bottomHalf]
        case .quarters: return [.topLeft, .topRight, .bottomLeft, .bottomRight]
        case .thirds:   return [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds]
        case .size:     return [.maximize, .center]
        case .move:     return [.nudgeLeft, .nudgeRight, .nudgeUp, .nudgeDown]
        case .resize:   return [.growWidth, .shrinkWidth, .growHeight, .shrinkHeight]
        case .display:  return [.nextDisplay, .previousDisplay]
        case .other:    return [.snapBack]
        }
    }
}
