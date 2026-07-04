import AppKit
import ScreenCaptureKit

/// Screen Recording access is a TCC permission, not an App Sandbox entitlement —
/// it must be granted per-app in System Settings and can't be requested with a
/// standard `NSApplication` runtime prompt.
final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    /// Attempts a lightweight check by asking ScreenCaptureKit for shareable content.
    /// This call throws if Screen Recording access hasn't been granted yet, and it's
    /// also what triggers the system's one-time permission prompt on first run.
    func ensureScreenRecordingPermission(completion: @escaping (Bool) -> Void) {
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )
                await MainActor.run { completion(true) }
            } catch {
                await MainActor.run { completion(false) }
            }
        }
    }

    /// Deep-links the user to the Screen Recording pane in System Settings.
    func promptForScreenRecordingAccess() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Access Required"
        alert.informativeText = "PartialScreenShare needs Screen Recording access to capture the region you select. Enable it in System Settings > Privacy & Security > Screen Recording, then relaunch the app."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
            NSWorkspace.shared.open(url)
        }
    }
}
