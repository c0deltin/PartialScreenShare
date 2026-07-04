import Cocoa
import ScreenCaptureKit

/// Ties one user-selected region to one `CaptureEngine` + one `MirrorWindow`
/// and owns their lifecycle.
final class CaptureSession: NSObject {
    let title: String
    private let regionInScreenCoordinates: CGRect
    private let screen: NSScreen

    private let engine = CaptureEngine()
    private var mirrorWindow: MirrorWindow?
    private var isStopped = false

    var onStop: (() -> Void)?

    init(title: String, regionInScreenCoordinates: CGRect, screen: NSScreen) {
        self.title = title
        self.regionInScreenCoordinates = regionInScreenCoordinates
        self.screen = screen
        super.init()
    }

    func start() {
        let window = MirrorWindow(title: "Partial Share — \(title)", aspectSize: regionInScreenCoordinates.size)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        mirrorWindow = window

        Task {
            let excluded = await CaptureSession.resolveSCWindow(for: window)

            engine.onFrame = { [weak self] sampleBuffer in
                DispatchQueue.main.async {
                    self?.mirrorWindow?.sampleBufferView.enqueue(sampleBuffer)
                }
            }

            engine.start(
                regionInScreenCoordinates: regionInScreenCoordinates,
                screen: screen,
                excludedWindows: excluded
            ) { [weak self] result in
                if case .failure(let error) = result {
                    self?.presentFailureAndStop(error)
                }
            }
        }
    }

    /// Triggered from the "Stop" menu item. Closing the window (rather than
    /// tearing down the capture directly) routes through `windowWillClose`
    /// below, so both this path and the user clicking the window's own close
    /// button converge on the same teardown logic.
    func stop() {
        mirrorWindow?.close()
    }

    private func stopCaptureAndNotify() {
        guard !isStopped else { return }
        isStopped = true
        engine.stop()
        mirrorWindow = nil
        onStop?()
    }

    private func presentFailureAndStop(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Couldn't Start Capture"
        alert.informativeText = error.localizedDescription
        alert.runModal()
        stop()
    }

    /// Looks up the `SCWindow` matching our own mirror window's `windowNumber`
    /// so it can be excluded from its own capture — without this, sharing the
    /// mirror window in a call would create an infinite hall-of-mirrors as
    /// soon as the region overlaps the mirror window itself.
    private static func resolveSCWindow(for window: NSWindow) async -> [SCWindow] {
        guard let content = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true) else {
            return []
        }
        return content.windows.filter { $0.windowID == CGWindowID(window.windowNumber) }
    }
}

extension CaptureSession: NSWindowDelegate {
    /// Fires whether the mirror window was closed via the menu bar's "Stop"
    /// item or the user clicking the window's own close button — either way,
    /// the capture must stop so we don't keep recording after the window is gone.
    func windowWillClose(_ notification: Notification) {
        stopCaptureAndNotify()
    }
}
