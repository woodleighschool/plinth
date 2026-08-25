import SwiftUI

struct KioskView: View {
    let session: KioskSession

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
