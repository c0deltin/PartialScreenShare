import Cocoa
import ScreenCaptureKit

enum CaptureEngineError: Error {
    case displayNotFound
}

/// Wraps a single `SCStream` cropped to a region via `sourceRect`, publishing
/// decoded frames as `CMSampleBuffer`s to a callback on the main actor.
final class CaptureEngine: NSObject {
    private var stream: SCStream?
    private let outputQueue = DispatchQueue(label: "com.partialscreenshare.capture-output")

    var onFrame: ((CMSampleBuffer) -> Void)?

    /// - Parameters:
    ///   - regionInScreenCoordinates: selection rect in the overlay view's
    ///     local coordinate space (AppKit convention: origin bottom-left, y up).
    ///   - screen: the `NSScreen` the region was selected on.
    ///   - excludedWindows: our own windows (mirror window, selection overlay)
    ///     that must never appear inside their own capture.
    func start(
        regionInScreenCoordinates: CGRect,
        screen: NSScreen,
        excludedWindows: [SCWindow],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

                guard let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                      let display = content.displays.first(where: { $0.displayID == displayID }) else {
                    throw CaptureEngineError.displayNotFound
                }

                let filter = SCContentFilter(display: display, excludingWindows: excludedWindows)

                let sourceRect = CoordinateConversion.sourceRect(
                    fromAppKitRegion: regionInScreenCoordinates,
                    screenHeight: screen.frame.height
                )

                let configuration = SCStreamConfiguration()
                configuration.sourceRect = sourceRect
                configuration.width = max(2, Int(sourceRect.width * screen.backingScaleFactor))
                configuration.height = max(2, Int(sourceRect.height * screen.backingScaleFactor))
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                configuration.showsCursor = true
                configuration.queueDepth = 5

                let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: outputQueue)
                try await stream.startCapture()

                self.stream = stream
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func stop() {
        let stream = self.stream
        self.stream = nil
        Task {
            try? await stream?.stopCapture()
        }
    }
}

extension CaptureEngine: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid else { return }
        onFrame?(sampleBuffer)
    }
}
