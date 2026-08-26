import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let session = KioskSession()
    private lazy var window = KioskWindow(
        kioskContentViewController: NSHostingController(
            rootView: KioskView(session: session)
        )
    )

    func applicationDidFinishLaunching(_: Notification) {
        let application = NSApplication.shared
        application.mainMenu = makeMainMenu()
        application.activate()
        window.present()
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
