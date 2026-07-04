import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItemController = StatusItemController()
        statusItemController?.install()

        PermissionManager.shared.ensureScreenRecordingPermission { granted in
            if !granted {
                PermissionManager.shared.promptForScreenRecordingAccess()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
