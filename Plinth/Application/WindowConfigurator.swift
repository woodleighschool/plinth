import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context _: Context) -> KioskWindowView {
        KioskWindowView()
    }

    func updateNSView(_: KioskWindowView, context _: Context) {}
}

final class KioskWindowView: NSView, NSWindowDelegate {
    private var observesScreenParameters = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            return
        }

        observeScreenParameters()

        window.delegate = self
        window.title = "Plinth"
        window.styleMask = [.borderless]
        window.level = .normal
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior.remove(.fullScreenPrimary)

        fitWindowToScreen()
        window.makeKeyAndOrderFront(nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        false
    }

    func windowDidChangeScreen(_: Notification) {
        fitWindowToScreen()
    }

    @objc private func screenParametersDidChange(_: Notification) {
        fitWindowToScreen()
    }

    private func observeScreenParameters() {
        guard !observesScreenParameters else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        observesScreenParameters = true
    }

    private func fitWindowToScreen() {
        guard let window,
              let screen = window.screen ?? NSScreen.main,
              window.frame != screen.frame
        else {
            return
        }

        window.setFrame(screen.frame, display: true)
    }
}
