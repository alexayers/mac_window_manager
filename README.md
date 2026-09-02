# Sizer

A native macOS window-management utility — a modern, Apple-Silicon-native
replacement for the unmaintained [SizeUp](https://www.irradiatedsoftware.com/sizeup/).
It snaps the focused window to halves, quarters, thirds, full screen, and center,
moves windows between displays, and nudges/resizes them — all via global hotkeys
and a menu-bar menu. It keeps SizeUp's default `⌃⌥⌘` shortcuts.

It runs as an agent app (no Dock icon) and drives other apps' windows through the
macOS Accessibility API — the same public-API approach used by Rectangle and
Spectacle. No private APIs.

> The product is named **Sizer** to avoid a process-name collision with Apple's
> own system `WindowManager` daemon (which powers Stage Manager / native tiling).

## Requirements

- macOS 13 or later (built and tested on macOS 26 / Apple Silicon)
- Swift toolchain (Xcode or the Swift command-line tools)

## Build & run

```sh
./run.sh          # build + sign + launch
# or
./build.sh        # build + sign only
open ./Sizer.app
```

`build.sh` compiles the SwiftPM executable, assembles `Sizer.app` (an
`LSUIElement` bundle), and ad-hoc code-signs it. Ad-hoc signing is enough to hold
Accessibility permission for local use.

## First launch: grant Accessibility permission

On first launch the app asks for Accessibility access (required to move other
apps' windows):

1. Click **Open System Settings** in the prompt.
2. Go to **Privacy & Security → Accessibility**.
3. Enable **Sizer** (add it with **+**, pointing at the built `.app`, if it isn't
   listed).

The app polls for the grant and starts responding to hotkeys once enabled — no
relaunch needed.

> If an ad-hoc rebuild changes the signature and the permission drops, remove and
> re-add the app in that list, or run
> `tccutil reset Accessibility com.diskrot.Sizer` and re-approve once.

## Default shortcuts (SizeUp defaults)

| Action      | Shortcut |
|-------------|----------|
| Left half   | `⌃⌥⌘ ←` |
| Right half  | `⌃⌥⌘ →` |
| Top half    | `⌃⌥⌘ ↑` |
| Bottom half | `⌃⌥⌘ ↓` |
| Maximize    | `⌃⌥⌘ M` |
| Center      | `⌃⌥⌘ C` |

Quarters, thirds, move-to-display, nudge, resize, and snap-back ship unbound and
are available from the menu-bar menu. Assign hotkeys to any of them in
**Preferences…** (a chord needs at least one of ⌃⌥⌘; press Escape to cancel or
Delete to clear while recording).

## Preferences

- Per-action shortcut recorders
- Screen-edge gap (reserves a margin on every screen)
- Move step / resize step (points)
- Launch at login

## Project layout

```
Package.swift                       SwiftPM manifest
Info.plist                          bundle template (LSUIElement, stable bundle id)
build.sh / run.sh                   CLI build + ad-hoc sign + launch
Sources/Sizer/
  main.swift                        entry point (accessory app)
  AppDelegate.swift                 object graph + wiring
  Actions.swift                     WindowAction enum + grouping + defaults
  Shortcut.swift                    Shortcut + Carbon/AppKit modifier + keycode maps
  ShortcutStore.swift               persisted user bindings
  CoordinateConverter.swift         AppKit ↔ Accessibility Y-flip (single source of truth)
  ScreenManager.swift               NSScreen geometry queries
  AccessibilityElement.swift        AXUIElement get/set + size→position→size
  WindowManager.swift               maps actions to target frames and applies them
  SnapBackStore.swift               remembers pre-snap frames
  HotKeyManager.swift               Carbon RegisterEventHotKey wrapper
  PermissionsManager.swift          Accessibility permission prompt + poll
  MenuBarController.swift           NSStatusItem menu
  PreferencesWindowController.swift preferences UI
  ShortcutRecorder.swift            key-capture button
  LaunchAtLogin.swift               SMAppService wrapper
  Settings.swift                    UserDefaults-backed tunables
```

## Notes on latest macOS

- Uses only public APIs; runs natively on Apple Silicon.
- The `⌃⌥⌘` defaults avoid the macOS 15+ `RegisterEventHotKey` Option-only
  regression and rarely clash with macOS Sequoia/Tahoe native tiling.
- For distribution to other Macs you'd notarize with a Developer ID; ad-hoc
  signing is fine for your own machine.

## Troubleshooting

**Shortcuts do nothing / the app "doesn't work."** Almost always this means
Accessibility permission isn't granted yet — moving other apps' windows is
impossible without it. Open the menu-bar menu: if you see
**"⚠️ Enable Accessibility Access…"** at the top, click it and enable **Sizer**
in the list. Pressing a shortcut while unpermitted now **beeps** and re-shows the
prompt (rather than silently failing). Hotkeys themselves are registered at
launch regardless of permission.

**Self-test (no permission or GUI needed).** Verifies the coordinate math and
hotkey registration:

```sh
swift build -c release && ./.build/release/Sizer --selftest
```

Expected: `ALL PASSED ✅`, including `registered 6/6 default hotkeys`.
