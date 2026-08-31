import Foundation
@testable import Plinth
import Testing
import WebKit

@MainActor
struct BrowserControllerTests {
    @Test func blockedTopLevelNavigationReportsVisibleFailure() throws {
        let policy = try URLPolicy(allowedHosts: ["example.invalid"])
        var failures: [BrowserFailure] = []
        let controller = BrowserController(urlPolicy: policy) {
            failures.append($0)
        }

        let allowed = try controller.handleTopLevelNavigation(
            to: #require(URL(string: "https://login.microsoftonline.com/"))
        )

        #expect(!allowed)
        #expect(failures == [.blockedNavigation(host: "login.microsoftonline.com")])
        #expect(failures.first?.title == "Navigation blocked")
        #expect(
            failures.first?.message ==
                "login.microsoftonline.com isn't allowed by the managed configuration."
        )
    }

    @Test func allowedTopLevelNavigationDoesNotReportFailure() throws {
        let policy = try URLPolicy(allowedHosts: ["example.invalid"])
        var failures: [BrowserFailure] = []
        let controller = BrowserController(urlPolicy: policy) {
            failures.append($0)
        }

        let allowed = try controller.handleTopLevelNavigation(
            to: #require(URL(string: "https://example.invalid/start"))
        )

        #expect(allowed)
        #expect(failures.isEmpty)
    }

    @Test func contextMenuContainsOnlyBrowserNavigation() throws {
        let policy = try URLPolicy(allowedHosts: ["example.invalid"])
        let controller = BrowserController(urlPolicy: policy) { _ in }
        let menu = controller.navigationMenu(for: WKWebView())

        #expect(menu.items.map(\.title) == ["Back", "Reload", "Forward"])
        #expect(menu.items.map(\.isEnabled) == [false, true, false])
        #expect(menu.items.map(\.keyEquivalent) == ["", "", ""])
    }
}
