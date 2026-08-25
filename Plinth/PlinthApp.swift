import SwiftUI

@main
struct PlinthApp: App {
    @State private var session = KioskSession()

    var body: some Scene {
        Window("Plinth", id: "kiosk") {
            KioskView(session: session)
        }
        .windowStyle(.plain)
        .restorationBehavior(.disabled)
        .defaultLaunchBehavior(.presented)
        .commands {
            CommandGroup(replacing: .appSettings) {}
            CommandGroup(replacing: .appTermination) {}
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .saveItem) {}
            CommandGroup(replacing: .printItem) {}
            CommandGroup(replacing: .importExport) {}
        }
    }
}
