import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context _: Context) -> KioskWindowView {
        KioskWindowView()
    }

    func updateNSView(_: KioskWindowView, context _: Context) {}
}

final class KioskWindowView: NSView, NSWindowDelegate {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        guard let window else {
            return
        }

        window.delegate = self
        window.title = "Plinth"
        window.styleMask = [.borderless]
        window.level = .normal
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior.remove(.fullScreenPrimary)

        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }

        window.makeKeyAndOrderFront(nil)
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        false
    }
}
