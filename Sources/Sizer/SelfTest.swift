import AppKit

/// Headless verification of the two riskiest, permission-free parts of the app:
/// the AppKit↔Accessibility coordinate flip and the action geometry, plus a
/// best-effort hotkey-registration round-trip. Run with `--selftest`; exits 0 on
/// success, 1 on failure. Does not touch the status bar or Accessibility.
enum SelfTest {
    private static var failures = 0

    static func run() -> Bool {
        failures = 0
        print("Sizer self-test")
        print("===============")

        testCoordinateFlip()
        testGeometry()
        testHotKeyRegistration()

        print("===============")
        if failures == 0 {
            print("ALL PASSED ✅")
            return true
        } else {
            print("\(failures) FAILURE(S) ❌")
            return false
        }
    }

    // MARK: - Checks

    private static func testCoordinateFlip() {
        print("\n[coordinate flip]")
        let H: CGFloat = 900

        // Top half of a 1440x900 primary screen: AppKit (0,450,1440,450) should
        // map to AX top-left (0,0,1440,450).
        let appKitTopHalf = CGRect(x: 0, y: 450, width: 1440, height: 450)
        expect(CoordinateConverter.flip(appKitTopHalf, primaryHeight: H),
               CGRect(x: 0, y: 0, width: 1440, height: 450),
               "AppKit top-half → AX top-left")

        // Bottom half AppKit (0,0,1440,450) → AX (0,450,1440,450).
        let appKitBottomHalf = CGRect(x: 0, y: 0, width: 1440, height: 450)
        expect(CoordinateConverter.flip(appKitBottomHalf, primaryHeight: H),
               CGRect(x: 0, y: 450, width: 1440, height: 450),
               "AppKit bottom-half → AX bottom-left")

        // The transform is its own inverse.
        let arbitrary = CGRect(x: 137, y: 211, width: 640, height: 480)
        let roundTrip = CoordinateConverter.flip(CoordinateConverter.flip(arbitrary, primaryHeight: H),
                                                 primaryHeight: H)
        expect(roundTrip, arbitrary, "flip is self-inverse")
    }

    private static func testGeometry() {
        print("\n[action geometry]  area 1440x900, window 400x300 @ (100,100)")
        let area = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let win = CGRect(x: 100, y: 100, width: 400, height: 300)
        let step: CGFloat = 60

        let cases: [(WindowAction, CGRect)] = [
            (.leftHalf,       CGRect(x: 0,    y: 0,   width: 720,  height: 900)),
            (.rightHalf,      CGRect(x: 720,  y: 0,   width: 720,  height: 900)),
            (.topHalf,        CGRect(x: 0,    y: 450, width: 1440, height: 450)),
            (.bottomHalf,     CGRect(x: 0,    y: 0,   width: 1440, height: 450)),
            (.topLeft,        CGRect(x: 0,    y: 450, width: 720,  height: 450)),
            (.topRight,       CGRect(x: 720,  y: 450, width: 720,  height: 450)),
            (.bottomLeft,     CGRect(x: 0,    y: 0,   width: 720,  height: 450)),
            (.bottomRight,    CGRect(x: 720,  y: 0,   width: 720,  height: 450)),
            (.leftThird,      CGRect(x: 0,    y: 0,   width: 480,  height: 900)),
            (.centerThird,    CGRect(x: 480,  y: 0,   width: 480,  height: 900)),
            (.rightThird,     CGRect(x: 960,  y: 0,   width: 480,  height: 900)),
            (.leftTwoThirds,  CGRect(x: 0,    y: 0,   width: 960,  height: 900)),
            (.rightTwoThirds, CGRect(x: 480,  y: 0,   width: 960,  height: 900)),
            (.maximize,       area),
            (.center,         CGRect(x: 520,  y: 300, width: 400,  height: 300)),
            (.nudgeLeft,      CGRect(x: 40,   y: 100, width: 400,  height: 300)),
            (.nudgeRight,     CGRect(x: 160,  y: 100, width: 400,  height: 300)),
            (.nudgeUp,        CGRect(x: 100,  y: 160, width: 400,  height: 300)),
            (.nudgeDown,      CGRect(x: 100,  y: 40,  width: 400,  height: 300)),
            (.growWidth,      CGRect(x: 100,  y: 100, width: 460,  height: 300)),
            (.shrinkWidth,    CGRect(x: 100,  y: 100, width: 340,  height: 300)),
            (.growHeight,     CGRect(x: 100,  y: 40,  width: 400,  height: 360)),
            (.shrinkHeight,   CGRect(x: 100,  y: 160, width: 400,  height: 240)),
        ]

        for (action, expected) in cases {
            guard let got = WindowGeometry.target(for: action, current: win, area: area,
                                                  moveStep: step, resizeStep: step) else {
                fail("\(action.rawValue): got nil")
                continue
            }
            expect(got, expected, action.rawValue)
        }
    }

    private static func testHotKeyRegistration() {
        print("\n[hotkey registration]")
        let expected = WindowAction.defaultBindings().count
        let manager = HotKeyManager()
        manager.register(WindowAction.defaultBindings())
        let got = manager.registeredCount
        manager.unregisterAll()
        if got == expected {
            print("  ✅ registered \(got)/\(expected) default hotkeys")
        } else {
            fail("registered \(got)/\(expected) default hotkeys")
        }
    }

    // MARK: - Helpers

    private static func expect(_ got: CGRect, _ want: CGRect, _ label: String) {
        if approxEqual(got, want) {
            print("  ✅ \(label)")
        } else {
            fail("\(label)\n       got  \(fmt(got))\n       want \(fmt(want))")
        }
    }

    private static func approxEqual(_ a: CGRect, _ b: CGRect) -> Bool {
        let t: CGFloat = 0.5
        return abs(a.minX - b.minX) < t && abs(a.minY - b.minY) < t
            && abs(a.width - b.width) < t && abs(a.height - b.height) < t
    }

    private static func fmt(_ r: CGRect) -> String {
        "(\(Int(r.minX)), \(Int(r.minY)), \(Int(r.width))x\(Int(r.height)))"
    }

    private static func fail(_ message: String) {
        failures += 1
        print("  ❌ \(message)")
    }
}
