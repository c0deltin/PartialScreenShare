import Cocoa

/// Coordinates one overlay window per connected display so the user can drag
/// a selection rectangle on whichever screen they click on; the other
/// screens' overlays are dismissed once a selection completes or is cancelled.
final class SelectionOverlayController {
    static let shared = SelectionOverlayController()

    private var windows: [SelectionOverlayWindow] = []
    private var completion: ((CGRect, NSScreen) -> Void)?

    private init() {}

    func beginSelection(completion: @escaping (_ regionInScreenCoordinates: CGRect, _ screen: NSScreen) -> Void) {
        guard windows.isEmpty else { return }
        self.completion = completion

        for screen in NSScreen.screens {
            let window = SelectionOverlayWindow(screen: screen)
            let view = SelectionOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.onSelectionComplete = { [weak self] rect in
                self?.finish(with: rect, screen: screen)
            }
            view.onCancel = { [weak self] in
                self?.cancel()
            }
            window.contentView = view
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }

        windows.first?.makeKey()

        // Signal "you're selecting a region" the same way the built-in
        // screenshot tool (Cmd+Shift+4) does, instead of the default arrow.
        NSCursor.crosshair.set()
    }

    private func finish(with rect: CGRect, screen: NSScreen) {
        let handler = completion
        dismissAll()
        handler?(rect, screen)
    }

    private func cancel() {
        dismissAll()
    }

    private func dismissAll() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        completion = nil
        NSCursor.arrow.set()
    }
}
