import AppKit

/// Preferences window: a shortcut recorder per action, plus general tunables
/// (screen-edge gap, move/resize step, launch at login) and a reset button.
/// Changes are persisted immediately and reported via `onChange` so hotkeys and
/// the menu can be re-synced.
final class PreferencesWindowController: NSWindowController {
    private let shortcuts: ShortcutStore
    private let onChange: () -> Void

    private var recorders: [WindowAction: ShortcutRecorderButton] = [:]

    init(shortcuts: ShortcutStore, onChange: @escaping () -> Void) {
        self.shortcuts = shortcuts
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 680),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Sizer Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Layout

    private func buildContent() {
        guard let window else { return }

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        for group in ActionGroup.allCases {
            stack.addArrangedSubview(makeHeader(group.rawValue))
            for action in group.actions {
                stack.addArrangedSubview(makeShortcutRow(action))
            }
        }

        stack.addArrangedSubview(makeHeader("General"))
        stack.addArrangedSubview(makeStepperRow(
            title: "Screen edge gap",
            value: Int(Settings.screenEdgeGap),
            max: 200
        ) { Settings.screenEdgeGap = CGFloat($0) })
        stack.addArrangedSubview(makeStepperRow(
            title: "Move step",
            value: Int(Settings.moveStep),
            max: 500
        ) { Settings.moveStep = CGFloat($0) })
        stack.addArrangedSubview(makeStepperRow(
            title: "Resize step",
            value: Int(Settings.resizeStep),
            max: 500
        ) { Settings.resizeStep = CGFloat($0) })
        stack.addArrangedSubview(makeLaunchAtLoginRow())
        stack.addArrangedSubview(makeResetRow())

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stack)
        scrollView.documentView = documentView

        let content = window.contentView!
        content.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: content.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor),

            documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            stack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: documentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: documentView.bottomAnchor),
        ])
    }

    private func makeHeader(_ text: String) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func makeShortcutRow(_ action: WindowAction) -> NSView {
        let label = NSTextField(labelWithString: action.title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 170).isActive = true

        let recorder = ShortcutRecorderButton()
        recorder.translatesAutoresizingMaskIntoConstraints = false
        recorder.widthAnchor.constraint(equalToConstant: 180).isActive = true
        recorder.shortcut = shortcuts.bindings[action]
        recorder.onCapture = { [weak self] captured in
            guard let self else { return }
            self.shortcuts.set(captured, for: action)
            self.refreshAllRecorders()
            self.onChange()
        }
        recorders[action] = recorder

        let row = NSStackView(views: [label, recorder])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        return row
    }

    private func makeStepperRow(title: String, value: Int, max: Int, apply: @escaping (Int) -> Void) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 170).isActive = true

        let valueField = NSTextField(labelWithString: "\(value) px")
        valueField.translatesAutoresizingMaskIntoConstraints = false
        valueField.widthAnchor.constraint(equalToConstant: 60).isActive = true

        let stepper = NSStepper()
        stepper.minValue = 0
        stepper.maxValue = Double(max)
        stepper.increment = 10
        stepper.integerValue = value
        stepper.valueWraps = false

        let handler = StepperHandler(field: valueField, apply: apply)
        stepper.target = handler
        stepper.action = #selector(StepperHandler.changed(_:))
        objc_setAssociatedObject(stepper, Unmanaged.passUnretained(stepper).toOpaque(),
                                 handler, .OBJC_ASSOCIATION_RETAIN)

        let row = NSStackView(views: [label, stepper, valueField])
        row.orientation = .horizontal
        row.spacing = 12
        row.alignment = .centerY
        return row
    }

    private func makeLaunchAtLoginRow() -> NSView {
        let checkbox = NSButton(checkboxWithTitle: "Launch at login",
                                target: self,
                                action: #selector(toggleLaunchAtLogin(_:)))
        checkbox.state = LaunchAtLogin.isEnabled ? .on : .off
        return checkbox
    }

    private func makeResetRow() -> NSView {
        let button = NSButton(title: "Reset Shortcuts to Defaults",
                              target: self,
                              action: #selector(resetShortcuts))
        button.bezelStyle = .rounded
        return button
    }

    // MARK: - Actions

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        LaunchAtLogin.set(sender.state == .on)
    }

    @objc private func resetShortcuts() {
        shortcuts.resetToDefaults()
        refreshAllRecorders()
        onChange()
    }

    private func refreshAllRecorders() {
        for (action, recorder) in recorders {
            recorder.shortcut = shortcuts.bindings[action]
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }
}

/// Small target object that keeps an `NSStepper` and its value label in sync and
/// applies the change. Retained via associated object on the stepper.
private final class StepperHandler: NSObject {
    private let field: NSTextField
    private let apply: (Int) -> Void

    init(field: NSTextField, apply: @escaping (Int) -> Void) {
        self.field = field
        self.apply = apply
    }

    @objc func changed(_ sender: NSStepper) {
        field.stringValue = "\(sender.integerValue) px"
        apply(sender.integerValue)
    }
}
