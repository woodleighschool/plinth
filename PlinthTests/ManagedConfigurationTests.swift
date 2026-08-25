import Foundation
@testable import Plinth
import Testing

struct ManagedConfigurationTests {
    @Test func loadsValidConfiguration() throws {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "Enabled")
        defaults.set("https://library.example.invalid/start", forKey: "StartURL")
        defaults.set(["example.invalid", "login.example.invalid"], forKey: "AllowedHosts")
        defaults.set(300, forKey: "IdleResetSeconds")
        defaults.set(false, forKey: "EphemeralSession")

        let state = try ManagedConfiguration.load(from: defaults)
        let configuration = try #require(state.configuration)

        #expect(configuration.startURL == URL(string: "https://library.example.invalid/start"))
        #expect(configuration.urlPolicy.allowedHosts == ["example.invalid", "login.example.invalid"])
        #expect(configuration.idleResetSeconds == 300)
        #expect(!configuration.ephemeralSession)
    }

    @Test func disabledConfigurationDoesNotRequireStartURL() throws {
        let state = try ManagedConfiguration.load(from: makeDefaults())
        #expect(state == .disabled)
    }

    @Test func rejectsMissingStartURL() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "Enabled")

        #expect(throws: ManagedConfiguration.ValidationError.missingStartURL) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsMalformedStartURL() {
        let defaults = enabledDefaults(startURL: "://not-a-url")

        #expect(throws: ManagedConfiguration.ValidationError.invalidStartURL) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsNonHTTPSStartURL() {
        let defaults = enabledDefaults(startURL: "http://example.invalid")

        #expect(throws: ManagedConfiguration.ValidationError.invalidStartURL) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func derivesAllowedHostFromStartURL() throws {
        let state = try ManagedConfiguration.load(
            from: enabledDefaults(startURL: "https://library.example.invalid/start")
        )
        let configuration = try #require(state.configuration)

        #expect(configuration.urlPolicy.allowedHosts == ["library.example.invalid"])
    }

    @Test func defaultsIdleResetToDisabled() throws {
        let state = try ManagedConfiguration.load(
            from: enabledDefaults(startURL: "https://example.invalid")
        )

        #expect(try #require(state.configuration).idleResetSeconds == 0)
    }

    @Test func rejectsNegativeIdleReset() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(-1, forKey: "IdleResetSeconds")

        #expect(throws: ManagedConfiguration.ValidationError.invalidIdleResetSeconds) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func defaultsToEphemeralSession() throws {
        let state = try ManagedConfiguration.load(
            from: enabledDefaults(startURL: "https://example.invalid")
        )

        #expect(try #require(state.configuration).ephemeralSession)
    }

    private func enabledDefaults(startURL: String) -> UserDefaults {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "Enabled")
        defaults.set(startURL, forKey: "StartURL")
        return defaults
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "au.edu.vic.woodleigh.PlinthTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
}

private extension ManagedConfigurationState {
    var configuration: ManagedConfiguration? {
        guard case let .enabled(configuration) = self else {
            return nil
        }
        return configuration
    }
}
