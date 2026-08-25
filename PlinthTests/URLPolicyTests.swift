import Foundation
@testable import Plinth
import Testing

struct URLPolicyTests {
    private let policy = try! URLPolicy(
        allowedHosts: [
            "woodleigh.vic.edu.au",
            "login.microsoftonline.com",
        ]
    )

    @Test func allowsExactHost() {
        #expect(policy.allows(URL(string: "https://woodleigh.vic.edu.au/")))
    }

    @Test func allowsSubdomain() {
        #expect(policy.allows(URL(string: "https://library.woodleigh.vic.edu.au/")))
        #expect(policy.allows(URL(string: "https://catalogue.library.woodleigh.vic.edu.au/")))
    }

    @Test func rejectsMaliciousSuffix() {
        #expect(!policy.allows(URL(string: "https://woodleigh.vic.edu.au.example.com/")))
    }

    @Test func rejectsHostPrefix() {
        #expect(!policy.allows(URL(string: "https://evilwoodleigh.vic.edu.au/")))
    }

    @Test func rejectsUnrelatedDomain() {
        #expect(!policy.allows(URL(string: "https://example.com/")))
    }

    @Test func rejectsHTTP() {
        #expect(!policy.allows(URL(string: "http://woodleigh.vic.edu.au/")))
    }

    @Test func rejectsFileURL() {
        #expect(!policy.allows(URL(fileURLWithPath: "/tmp/index.html")))
    }

    @Test func rejectsMalformedURL() {
        #expect(!policy.allows(URL(string: "not a URL")))
    }

    @Test func allowsExplicitAuthenticationHost() {
        #expect(policy.allows(URL(string: "https://login.microsoftonline.com/common/oauth2/authorize")))
    }

    @Test func rejectsInvalidAllowedHost() {
        #expect(throws: URLPolicy.ValidationError.invalidAllowedHost(".example.com")) {
            try URLPolicy(allowedHosts: [".example.com"])
        }
    }
}
