import Foundation
@testable import Plinth
import Testing

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
}
