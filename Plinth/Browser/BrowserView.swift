import AppKit
import OSLog
import SwiftUI
import WebKit

struct BrowserView: NSViewRepresentable {
    let configuration: ManagedConfiguration

    func makeCoordinator() -> BrowserController {
        BrowserController(configuration: configuration)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = configuration.ephemeralSession
            ? .nonPersistent()
            : .default()

        let webView = KioskWebView(
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

final class KioskWebView: WKWebView {
    override func menu(for _: NSEvent) -> NSMenu? {
        nil
    }
}

final class BrowserController: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let configuration: ManagedConfiguration

    init(configuration: ManagedConfiguration) {
        self.configuration = configuration
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
            if configuration.urlPolicy.allows(url) {
                webView.load(navigationAction.request)
            } else {
                logBlockedNavigation(url)
            }
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame?.isMainFrame == true {
            if configuration.urlPolicy.allows(url) {
                decisionHandler(.allow)
            } else {
                logBlockedNavigation(url)
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

        if configuration.urlPolicy.allows(url) {
            webView.load(navigationAction.request)
        } else {
            logBlockedNavigation(url)
        }

        return nil
    }

    private func logBlockedNavigation(_ url: URL) {
        let host = url.host ?? "unknown"
        Log.browser.notice("Blocked top-level navigation to host \(host, privacy: .public)")
    }
}
