import AppKit
import OSLog
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let session = KioskSession()
    private lazy var window = KioskWindow(
        contentViewController: NSHostingController(
            rootView: KioskView(session: session)
        )
    )

    private var sessionTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_: Notification) {
        let application = NSApplication.shared
        application.mainMenu = makeMainMenu()

        guard window.present() else {
            Log.app.error("Kiosk window could not be presented; assessment session will not start")
            return
        }

        application.activate()
        sessionTask = Task { [session] in
            await session.run()
        }
    }

    func applicationWillTerminate(_: Notification) {
        sessionTask?.cancel()
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem(
            title: "Edit",
            action: nil,
            keyEquivalent: ""
        )
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        editMenu.addItem(
            withTitle: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        editMenu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        editMenu.addItem(
            withTitle: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )

        return mainMenu
    }
}
