import SwiftUI

struct KioskView: View {
    let session: KioskSession

    var body: some View {
        ZStack {
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

            if session.presentsAdministratorEscape {
                AdministratorEscapePrompt(
                    dismiss: session.dismissAdministratorEscape,
                    submit: session.submitAdministratorEscapeCode
                )
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
    }
}

private struct AdministratorEscapePrompt: View {
    let dismiss: () -> Void
    let submit: (String) -> Bool

    @State private var code = ""
    @State private var showsIncorrectCode = false
    @FocusState private var codeIsFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("Administrator exit")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter the managed escape code to stop Plinth.")
                    .foregroundStyle(.secondary)

                SecureField("Escape code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .focused($codeIsFocused)
                    .onSubmit(attemptExit)

                if showsIncorrectCode {
                    Text("The escape code is incorrect.")
                        .foregroundStyle(.red)
                }

                HStack {
                    Spacer()

                    Button("Cancel", role: .cancel, action: dismiss)
                        .keyboardShortcut(.cancelAction)

                    Button("Exit Plinth", action: attemptExit)
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 420)
            .background(.regularMaterial, in: .rect(cornerRadius: 12))
            .shadow(radius: 24)
        }
        .onAppear {
            codeIsFocused = true
        }
    }

    private func attemptExit() {
        guard !code.isEmpty else {
            return
        }

        if submit(code) {
            code = ""
        } else {
            code = ""
            showsIncorrectCode = true
            codeIsFocused = true
        }
    }
}

private struct StatusView: View {
    let title: String
    let message: String?
    var showsProgress = false

    var body: some View {
        VStack(spacing: 16) {
            if showsProgress {
                ProgressView()
                    .controlSize(.large)
            } else {
                Image(systemName: "display")
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
