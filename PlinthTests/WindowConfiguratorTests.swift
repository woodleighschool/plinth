import AppKit
@testable import Plinth
import Testing

@MainActor
struct WindowConfiguratorTests {
    @Test func followsScreenFrameAfterDisplayGeometryChanges() throws {
        let screen = try #require(NSScreen.main)
        let window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = KioskWindowView()

        window.setFrame(screen.frame.insetBy(dx: 100, dy: 100), display: false)
        #expect(window.frame != screen.frame)

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        #expect(window.frame == screen.frame)
    }
}
