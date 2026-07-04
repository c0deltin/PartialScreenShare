import Cocoa

/// A perfectly ordinary titled window — deliberately so. Teams/Meet/Zoom's
/// screen-share pickers only list normal, on-screen, non-minimized windows,
/// so this must NOT be borderless, NOT excluded from the window list, and
/// NOT set to `.none` sharing type.
final class MirrorWindow: NSWindow {
    let sampleBufferView: SampleBufferView

    init(title: String, aspectSize: CGSize) {
        let initialSize = MirrorWindow.fittedSize(for: aspectSize)
        let view = SampleBufferView(frame: NSRect(origin: .zero, size: initialSize))
        self.sampleBufferView = view

        super.init(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = title
        self.contentView = view
        self.contentAspectRatio = aspectSize
        self.isReleasedWhenClosed = false
        self.center()
    }

    private static func fittedSize(for aspectSize: CGSize, maxDimension: CGFloat = 640) -> CGSize {
        guard aspectSize.width > 0, aspectSize.height > 0 else { return CGSize(width: 480, height: 270) }
        let scale = maxDimension / max(aspectSize.width, aspectSize.height)
        return CGSize(width: aspectSize.width * scale, height: aspectSize.height * scale)
    }
}
