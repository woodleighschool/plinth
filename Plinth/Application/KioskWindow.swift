import AppKit

@MainActor
final class KioskWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    convenience init(contentViewController: NSViewController) {
        self.init(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.contentViewController = contentViewController
        title = "Plinth"
        backgroundColor = .windowBackgroundColor
        hasShadow = false
        isOpaque = true
        isMovable = false
        acceptsMouseMovedEvents = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func present() -> Bool {
        guard fitToScreen() else {
            return false
        }

        makeKeyAndOrderFront(nil)
        return isVisible
    }

    @objc private func screenParametersDidChange(_: Notification) {
        _ = fitToScreen()
    }

    @discardableResult
    private func fitToScreen() -> Bool {
        guard let screen = screen ?? NSScreen.main else {
            return false
        }

        if frame != screen.frame {
            setFrame(screen.frame, display: isVisible)
        }
        return !frame.isEmpty
    }
}
