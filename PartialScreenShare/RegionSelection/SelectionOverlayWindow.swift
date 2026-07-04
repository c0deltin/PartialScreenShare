import Cocoa

/// One transparent, click-to-drag overlay window per display. Sits above
/// everything (including other apps) so the user can drag a selection
/// rectangle directly on top of whatever is currently on screen.
final class SelectionOverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        ignoresMouseEvents = false
        hasShadow = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
