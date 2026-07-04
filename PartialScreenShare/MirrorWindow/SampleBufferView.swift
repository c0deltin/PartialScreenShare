import Cocoa
import AVFoundation

/// Renders incoming `CMSampleBuffer`s with `AVSampleBufferDisplayLayer` — a
/// zero-copy path that avoids re-encoding frames through NSImage/CGImage.
final class SampleBufferView: NSView {
    let displayLayer = AVSampleBufferDisplayLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func makeBackingLayer() -> CALayer {
        displayLayer.videoGravity = .resizeAspect
        return displayLayer
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        if displayLayer.status == .failed {
            displayLayer.flush()
        }
        displayLayer.enqueue(sampleBuffer)
    }
}
