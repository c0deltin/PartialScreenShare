import Cocoa
import ScreenCaptureKit

/// Ties one user-selected region to one `CaptureEngine` + one `MirrorWindow`
/// and owns their lifecycle.
final class CaptureSession {
    let title: String
    private let regionInScreenCoordinates: CGRect
    private let screen: NSScreen

    private let engine = CaptureEngine()
    private var mirrorWindow: MirrorWindow?

    var onStop: (() -> Void)?

    init(title: String, regionInScreenCoordinates: CGRect, screen: NSScreen) {
        self.title = title
        self.regionInScreenCoordinates = regionInScreenCoordinates
        self.screen = screen
    }

    func start() {
        let window = MirrorWindow(title: "Partial Share — \(title)", aspectSize: regionInScreenCoordinates.size)
        window.delegate = nil
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

    func stop() {
        engine.stop()
        mirrorWindow?.close()
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
