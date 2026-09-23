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
        ManagedWebView(configuration: configuration) {
            failure = $0
        }
        .alert(
            failure?.title ?? "Navigation blocked",
            isPresented: failureIsPresented
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let failure {
                Text(failure.message)
            }
        }
    }

    private var failureIsPresented: Binding<Bool> {
        Binding {
            failure != nil
        } set: { isPresented in
            if !isPresented {
                failure = nil
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
        webView.isHidden = !context.environment.isEnabled
        webView.isInspectable = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.startContextMenuMonitoring(for: webView)
        webView.load(URLRequest(url: configuration.startURL))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // A SwiftUI overlay alone leaves AppKit's keyboard focus and input active.
        // Hiding the native view suspends input without discarding the page.
        webView.isHidden = !context.environment.isEnabled
    }

    static func dismantleNSView(
        _ webView: WKWebView,
        coordinator: BrowserController
    ) {
        coordinator.stopContextMenuMonitoring()
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}

@MainActor
final class BrowserController: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let urlPolicy: URLPolicy
    private let reportFailure: @MainActor (BrowserFailure) -> Void
    private weak var webView: WKWebView?
    private var contextMenuMonitor: Any?

    init(
        urlPolicy: URLPolicy,
        reportFailure: @escaping @MainActor (BrowserFailure) -> Void
    ) {
        self.urlPolicy = urlPolicy
        self.reportFailure = reportFailure
    }

    func startContextMenuMonitoring(for webView: WKWebView) {
        guard contextMenuMonitor == nil else {
            return
        }

        self.webView = webView
        contextMenuMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self,
                  Self.isContextMenuClick(event),
                  let webView = self.webView,
                  !webView.isHiddenOrHasHiddenAncestor,
                  event.window === webView.window,
                  webView.bounds.contains(
                      webView.convert(event.locationInWindow, from: nil)
                  )
            else {
                return event
            }

            NSMenu.popUpContextMenu(
                navigationMenu(for: webView),
                with: event,
                for: webView
            )
            return nil
        }
    }

    func stopContextMenuMonitoring() {
        guard let contextMenuMonitor else {
            return
        }

        NSEvent.removeMonitor(contextMenuMonitor)
        self.contextMenuMonitor = nil
        webView = nil
    }

    func navigationMenu(for webView: WKWebView) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(
            menuItem(
                title: "Back",
                action: #selector(goBack(_:)),
                isEnabled: webView.canGoBack
            )
        )
        menu.addItem(
            menuItem(
                title: "Reload",
                action: #selector(reload(_:)),
                isEnabled: true
            )
        )
        menu.addItem(
            menuItem(
                title: "Forward",
                action: #selector(goForward(_:)),
                isEnabled: webView.canGoForward
            )
        )
        return menu
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

    private static func isContextMenuClick(_ event: NSEvent) -> Bool {
        event.type == .rightMouseDown ||
            (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
    }

    private func menuItem(
        title: String,
        action: Selector,
        isEnabled: Bool
    ) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: action,
            keyEquivalent: ""
        )
        item.target = self
        item.isEnabled = isEnabled
        return item
    }

    @objc private func goBack(_: NSMenuItem) {
        webView?.goBack()
    }

    @objc private func reload(_: NSMenuItem) {
        webView?.reload()
    }

    @objc private func goForward(_: NSMenuItem) {
        webView?.goForward()
    }
}
