import AppKit

/// A minimal preferences window — currently just the region-border color
/// picker. Plain AppKit rather than SwiftUI's `Settings` scene: reliably
/// triggering that scene from an NSStatusItem menu in an accessory
/// (menu-bar-only) app is a known, still-unresolved pain point on recent
/// macOS versions, so a small AppKit window is simpler and more reliable.
final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()

    private var colorWell: NSColorWell!

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 110),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)

        let enabledCheckbox = NSButton(
            checkboxWithTitle: "Show border around shared region",
            target: self,
            action: #selector(enabledCheckboxChanged(_:))
        )
        enabledCheckbox.state = BorderPreference.shared.isEnabled ? .on : .off

        let label = NSTextField(labelWithString: "Border color:")

        let colorWell = NSColorWell(frame: .zero)
        colorWell.color = BorderPreference.shared.color
        colorWell.target = self
        colorWell.action = #selector(colorWellChanged(_:))
        colorWell.isEnabled = BorderPreference.shared.isEnabled
        self.colorWell = colorWell

        let colorRow = NSStackView(views: [label, colorWell])
        colorRow.orientation = .horizontal
        colorRow.spacing = 8

        let stack = NSStackView(views: [enabledCheckbox, colorRow])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(stack)
        window.contentView = contentView

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func enabledCheckboxChanged(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        BorderPreference.shared.isEnabled = isEnabled
        colorWell.isEnabled = isEnabled
    }

    @objc private func colorWellChanged(_ sender: NSColorWell) {
        BorderPreference.shared.color = sender.color
    }
}
