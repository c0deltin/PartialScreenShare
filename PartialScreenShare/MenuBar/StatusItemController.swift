import Cocoa

final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private var activeSessions: [CaptureSession] = []
    private var sessionCounter = 0

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "rectangle.dashed.badge.record", accessibilityDescription: "PartialScreenShare")
        }
        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(withTitle: "New Region Share…", action: #selector(startNewShare), keyEquivalent: "n")
            .target = self

        menu.addItem(.separator())

        if activeSessions.isEmpty {
            let emptyItem = NSMenuItem(title: "No active shares", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for session in activeSessions {
                let item = NSMenuItem(title: "Stop “\(session.title)”", action: #selector(stopSession(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = session
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferences…", action: #selector(showPreferences), keyEquivalent: ",")
            .target = self

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit PartialScreenShare", action: #selector(quit), keyEquivalent: "q")
            .target = self

        return menu
    }

    private func refreshMenu() {
        statusItem?.menu = buildMenu()
    }

    @objc private func startNewShare() {
        PermissionManager.shared.ensureScreenRecordingPermission { [weak self] granted in
            guard let self else { return }
            guard granted else {
                PermissionManager.shared.promptForScreenRecordingAccess()
                return
            }
            SelectionOverlayController.shared.beginSelection { [weak self] rect, screen in
                self?.startSession(for: rect, on: screen)
            }
        }
    }

    private func startSession(for rect: CGRect, on screen: NSScreen) {
        sessionCounter += 1
        let session = CaptureSession(title: "Region \(sessionCounter)", regionInScreenCoordinates: rect, screen: screen)
        session.onStop = { [weak self, weak session] in
            guard let self, let session else { return }
            self.activeSessions.removeAll { $0 === session }
            self.refreshMenu()
        }
        activeSessions.append(session)
        refreshMenu()
        session.start()
    }

    @objc private func stopSession(_ sender: NSMenuItem) {
        guard let session = sender.representedObject as? CaptureSession else { return }
        session.stop()
    }

    @objc private func showPreferences() {
        PreferencesWindowController.shared.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
