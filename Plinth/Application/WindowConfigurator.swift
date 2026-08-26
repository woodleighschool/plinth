import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context _: Context) -> KioskWindowView {
        KioskWindowView()
    }

    func updateNSView(_: KioskWindowView, context _: Context) {}
}

final class KioskWindowView: NSView {
    private var observesScreenParameters = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            stopObservingScreenParameters()
            return
        }

        observeScreenParameters()
        fitWindowToScreen()

        window.isMovable = false
        window.acceptsMouseMovedEvents = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    private func stopObservingScreenParameters() {
        guard observesScreenParameters else {
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        observesScreenParameters = false
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
