import AppKit

/// Persists the region-border settings (whether it's shown at all, and its
/// color) across launches, and notifies observers when either changes.
final class BorderPreference {
    static let shared = BorderPreference()
    static let didChangeNotification = Notification.Name("BorderPreference.didChange")

    private let defaults = UserDefaults.standard
    private let enabledKey = "borderEnabled"
    private let colorKey = "borderColorComponents" // [red, green, blue, alpha] in the sRGB space

    /// Takes precedence over `color`: when `false`, no border is shown
    /// regardless of the stored color.
    var isEnabled: Bool {
        get { defaults.object(forKey: enabledKey) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: enabledKey)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }

    var color: NSColor {
        get {
            guard let components = defaults.array(forKey: colorKey) as? [Double], components.count == 4 else {
                return .controlAccentColor
            }
            return NSColor(srgbRed: components[0], green: components[1], blue: components[2], alpha: components[3])
        }
        set {
            let rgba = newValue.usingColorSpace(.sRGB) ?? NSColor.controlAccentColor.usingColorSpace(.sRGB)!
            defaults.set([rgba.redComponent, rgba.greenComponent, rgba.blueComponent, rgba.alphaComponent], forKey: colorKey)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }

    private init() {}
}
