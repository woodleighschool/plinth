import SwiftUI

@main
struct PlinthApp: App {
    @State private var session = KioskSession()

    var body: some Scene {
        Window("Plinth", id: "kiosk") {
            KioskView(session: session)
                .toolbarVisibility(.hidden, for: .windowToolbar)
                .ignoresSafeArea(.container, edges: .top)
                .windowDismissBehavior(.disabled)
                .windowMinimizeBehavior(.disabled)
                .windowResizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
        }
        .windowStyle(.titleBar)
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
