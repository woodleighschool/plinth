import SwiftUI

struct KioskView: View {
    let session: KioskSession

    @State private var administratorEscapeCode = ""

    var body: some View {
        Group {
            switch session.presentation {
            case .startup:
                StatusView(
                    title: "Preparing assessment browser…",
                    message: nil,
                    showsProgress: true
                )
            case .maintenance:
                StatusView(
                    title: "Assessment browser disabled for maintenance",
                    message: "An administrator can re-enable this Mac through managed settings."
                )
            case .scheduledOff:
                StatusView(
                    title: "Assessment browser outside managed display hours",
                    message: "It will resume automatically at the next scheduled time."
                )
            case let .configurationError(message):
                StatusView(
                    title: "Assessment browser configuration error",
                    message: message
                )
            case .unavailable:
                StatusView(
                    title: "Assessment browser unavailable",
                    message: "Contact IT for assistance."
                )
            case let .browser(browser):
                BrowserView(configuration: browser.configuration)
                    .id(browser.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .background {
            WindowConfigurator()
        }
        .task {
            await session.run()
        }
        .alert("Administrator exit", isPresented: administratorEscapeIsPresented) {
            SecureField("Escape code", text: $administratorEscapeCode)
            Button("Cancel", role: .cancel) {}
            Button("Exit Plinth") {
                let code = administratorEscapeCode
                administratorEscapeCode = ""
                _ = session.submitAdministratorEscapeCode(code)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(administratorEscapeCode.isEmpty)
        } message: {
            Text("Enter the managed escape code to stop Plinth.")
        }
    }

    private var administratorEscapeIsPresented: Binding<Bool> {
        Binding {
            session.presentsAdministratorEscape
        } set: { isPresented in
            if !isPresented {
                administratorEscapeCode = ""
                session.dismissAdministratorEscape()
            }
        }
    }
}

struct StatusView: View {
    let title: String
    let message: String?
    var showsProgress = false
    var systemImage = "display"

    var body: some View {
        VStack(spacing: 16) {
            if showsProgress {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            if let message {
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }
        }
        .padding(40)
    }
}
