import AppKit
import OSLog
import SwiftUI
import WebKit

nonisolated enum BrowserFailure: Equatable, Sendable {
    case blockedNavigation(host: String?)

    var title: String {
        "Navigation blocked"
    }

    var message: String {
        switch self {
        case let .blockedNavigation(host):
            if let host {
                "\(host) isn't allowed by the managed configuration."
            } else {
                "This destination isn't allowed by the managed configuration."
            }
        }
    }
}

struct BrowserView: View {
    let configuration: ManagedConfiguration

    @State private var failure: BrowserFailure?

    var body: some View {
        ZStack {
            ManagedWebView(configuration: configuration) {
                failure = $0
            }

            if let failure {
                StatusView(
                    title: failure.title,
                    message: failure.message,
                    systemImage: "exclamationmark.triangle"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
            }
        }
    }
}

private struct ManagedWebView: NSViewRepresentable {
    let configuration: ManagedConfiguration
    let reportFailure: @MainActor (BrowserFailure) -> Void

    func makeCoordinator() -> BrowserController {
        BrowserController(
            urlPolicy: configuration.urlPolicy,
            reportFailure: reportFailure
        )
    }

    func makeNSView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = configuration.ephemeralSession
            ? .nonPersistent()
            : .default()

        let webView = WKWebView(
            frame: .zero,
            configuration: webConfiguration
        )
        webView.isInspectable = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: configuration.startURL))
        return webView
    }

    func updateNSView(_: WKWebView, context _: Context) {}

    static func dismantleNSView(
        _ webView: WKWebView,
        coordinator _: BrowserController
    ) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}

@MainActor
final class BrowserController: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let urlPolicy: URLPolicy
    private let reportFailure: @MainActor (BrowserFailure) -> Void

    init(
        urlPolicy: URLPolicy,
        reportFailure: @escaping @MainActor (BrowserFailure) -> Void
    ) {
        self.urlPolicy = urlPolicy
        self.reportFailure = reportFailure
    }

    func handleTopLevelNavigation(to url: URL) -> Bool {
        guard urlPolicy.allows(url) else {
            logBlockedNavigation(url)
            reportFailure(.blockedNavigation(host: url.host))
            return false
        }

        return true
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        guard !navigationAction.shouldPerformDownload,
              let url = navigationAction.request.url
        else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            if handleTopLevelNavigation(to: url) {
                webView.load(navigationAction.request)
            }
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame?.isMainFrame == true {
            if handleTopLevelNavigation(to: url) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
            return
        }

        switch url.scheme?.lowercased() {
        case "https", "about", "data", "blob":
            decisionHandler(.allow)
        default:
            decisionHandler(.cancel)
        }
    }

    func webView(
        _: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .cancel)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url
        else {
            return nil
        }

        if handleTopLevelNavigation(to: url) {
            webView.load(navigationAction.request)
        }

        return nil
    }

    private func logBlockedNavigation(_ url: URL) {
        let host = url.host ?? "unknown"
        Log.browser.notice("Blocked top-level navigation to host \(host, privacy: .public)")
    }
}
