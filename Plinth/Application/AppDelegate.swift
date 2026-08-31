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
}
