import Cocoa

/// A perfectly ordinary titled window — deliberately so. Teams/Meet/Zoom's
/// screen-share pickers only list normal, on-screen, non-minimized windows,
/// so this must NOT be borderless, NOT excluded from the window list, and
/// NOT set to `.none` sharing type.
///
/// It's also click-through (`ignoresMouseEvents`): since it can end up
/// sitting on top of the exact content the user is presenting, clicks must
/// pass through to whatever's underneath rather than getting stuck on the
/// preview. That means the standard close/miniaturize/resize affordances
/// would never receive a click either, so they're dropped from the style
/// mask entirely — closing a session goes through the menu bar's "Stop"
/// item instead.
final class MirrorWindow: NSWindow {
    let sampleBufferView: SampleBufferView

    /// The content view is sized to exactly match the captured region, in
    /// points — not scaled down for on-screen convenience — so the window
    /// shows (and therefore shares) the capture at its native resolution
    /// rather than a downscaled preview.
    init(title: String, aspectSize: CGSize) {
        let contentSize = aspectSize.width > 0 && aspectSize.height > 0 ? aspectSize : CGSize(width: 480, height: 270)
        let view = SampleBufferView(frame: NSRect(origin: .zero, size: contentSize))
        self.sampleBufferView = view

        super.init(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        self.title = title
        self.contentView = view
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true
        self.center()
    }
}
