import Cocoa

final class SelectionOverlayView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var dragStart: CGPoint?
    private var currentRect: CGRect = .zero

    private let dimColor = NSColor.black.withAlphaComponent(0.25)
    private let strokeColor = NSColor.controlAccentColor
    private let readoutAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white
    ]

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        dimColor.setFill()
        bounds.fill()

        guard currentRect != .zero else { return }

        // Punch a clear "hole" where the selection is so the user sees the
        // real screen content inside the rectangle, dimmed everywhere else.
        NSGraphicsContext.saveGraphicsState()
        NSColor.clear.setFill()
        currentRect.fill(using: .copy)
        NSGraphicsContext.restoreGraphicsState()

        strokeColor.setStroke()
        let path = NSBezierPath(rect: currentRect)
        path.lineWidth = 2
        path.stroke()

        let readout = "\(Int(currentRect.width)) × \(Int(currentRect.height))" as NSString
        let size = readout.size(withAttributes: readoutAttributes)
        let readoutOrigin = CGPoint(
            x: currentRect.midX - size.width / 2,
            y: min(currentRect.maxY + 6, bounds.height - size.height)
        )
        readout.draw(at: readoutOrigin, withAttributes: readoutAttributes)
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = convert(event.locationInWindow, from: nil)
        currentRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = dragStart else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            dragStart = nil
            currentRect = .zero
            needsDisplay = true
        }

        guard currentRect.width > 4, currentRect.height > 4 else { return }
        onSelectionComplete?(currentRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }
}
