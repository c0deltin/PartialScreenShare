import Cocoa

/// A persistent, click-through outline drawn directly around the active
/// capture region on the source screen. Lets the user see at a glance what's
/// currently being shared without needing to look at (or hunt down) the
/// mirror window itself. Purely cosmetic — like the mirror window, it must
/// be excluded from the capture (see `CaptureSession`) so the border doesn't
/// show up in the shared video.
final class RegionBorderWindow: NSWindow {
    init(region: CGRect) {
        super.init(
            contentRect: region,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating
        ignoresMouseEvents = true
        hasShadow = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        contentView = RegionBorderView(frame: NSRect(origin: .zero, size: region.size))
    }
}

private final class RegionBorderView: NSView {
    private let lineWidth: CGFloat = 3

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferenceDidChange),
            name: BorderPreference.didChangeNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func preferenceDidChange() {
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        BorderPreference.shared.color.setStroke()
        let path = NSBezierPath(rect: bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2))
        path.lineWidth = lineWidth
        path.stroke()
    }
}
