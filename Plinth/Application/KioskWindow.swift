import AppKit

final class KioskWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    convenience init(kioskContentViewController: NSViewController) {
        self.init(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        contentViewController = kioskContentViewController
        backgroundColor = .black
        hasShadow = false
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

    func present() {
        fitToScreen()
        makeKeyAndOrderFront(nil)
    }

    @objc private func screenParametersDidChange(_: Notification) {
        fitToScreen()
    }

    private func fitToScreen() {
        guard let screen = screen ?? NSScreen.main,
              frame != screen.frame
        else {
            return
        }

        setFrame(screen.frame, display: isVisible)
    }
}
