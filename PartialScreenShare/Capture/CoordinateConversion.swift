import CoreGraphics

/// Pure coordinate math, kept separate from `CaptureEngine` so it's testable
/// without spinning up ScreenCaptureKit.
enum CoordinateConversion {
    /// Converts a selection rect from AppKit's coordinate space (origin
    /// bottom-left of the screen, y increases upward) to the top-left-origin
    /// space `SCStreamConfiguration.sourceRect` expects.
    static func sourceRect(fromAppKitRegion region: CGRect, screenHeight: CGFloat) -> CGRect {
        CGRect(
            x: region.origin.x,
            y: screenHeight - region.maxY,
            width: region.width,
            height: region.height
        )
    }
}
