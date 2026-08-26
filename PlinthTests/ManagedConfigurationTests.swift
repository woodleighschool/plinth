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
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("08:00", forKey: "DisplayOnTime")
        defaults.set("17:30", forKey: "DisplayOffTime")
        defaults.set(["Monday", "Wednesday", "Friday"], forKey: "DisplayDays")

        let state = try ManagedConfiguration.load(from: defaults)
        let configuration = try #require(state.configuration)

        #expect(configuration.startURL == URL(string: "https://library.example.invalid/start"))
        #expect(configuration.urlPolicy.allowedHosts == ["example.invalid", "login.example.invalid"])
        #expect(configuration.idleResetSeconds == 300)
        #expect(!configuration.ephemeralSession)
        #expect(configuration.displaySchedule?.onTime.hour == 8)
        #expect(configuration.displaySchedule?.onTime.minute == 0)
        #expect(configuration.displaySchedule?.offTime.hour == 17)
        #expect(configuration.displaySchedule?.offTime.minute == 30)
        #expect(configuration.displaySchedule?.days == [.monday, .wednesday, .friday])
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

    @Test func defaultsDisplaySchedulingToDisabled() throws {
        let state = try ManagedConfiguration.load(
            from: enabledDefaults(startURL: "https://example.invalid")
        )

        #expect(try #require(state.configuration).displaySchedule == nil)
    }

    @Test func defaultsDisplayDaysToWeekdays() throws {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("08:00", forKey: "DisplayOnTime")
        defaults.set("17:00", forKey: "DisplayOffTime")

        let state = try ManagedConfiguration.load(from: defaults)

        #expect(
            try #require(state.configuration).displaySchedule?.days ==
                DisplaySchedule.Weekday.weekdays
        )
    }

    @Test func rejectsInvalidDisplayScheduleEnabled() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set("true", forKey: "DisplayScheduleEnabled")

        #expect(throws: ManagedConfiguration.ValidationError.invalidDisplayScheduleEnabled) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsIncompleteDisplaySchedule() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("08:00", forKey: "DisplayOnTime")

        #expect(throws: ManagedConfiguration.ValidationError.invalidDisplaySchedule) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsMalformedDisplayTime() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("8:00", forKey: "DisplayOnTime")
        defaults.set("17:00", forKey: "DisplayOffTime")

        #expect(throws: ManagedConfiguration.ValidationError.invalidDisplaySchedule) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsIdenticalDisplayTimes() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("08:00", forKey: "DisplayOnTime")
        defaults.set("08:00", forKey: "DisplayOffTime")

        #expect(throws: ManagedConfiguration.ValidationError.invalidDisplaySchedule) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func rejectsInvalidDisplayDays() {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(true, forKey: "DisplayScheduleEnabled")
        defaults.set("08:00", forKey: "DisplayOnTime")
        defaults.set("17:00", forKey: "DisplayOffTime")
        defaults.set(["Weekdays"], forKey: "DisplayDays")

        #expect(throws: ManagedConfiguration.ValidationError.invalidDisplaySchedule) {
            try ManagedConfiguration.load(from: defaults)
        }
    }

    @Test func disabledScheduleIgnoresOtherDisplayValues() throws {
        let defaults = enabledDefaults(startURL: "https://example.invalid")
        defaults.set(false, forKey: "DisplayScheduleEnabled")
        defaults.set("invalid", forKey: "DisplayOnTime")
        defaults.set(42, forKey: "DisplayDays")

        let state = try ManagedConfiguration.load(from: defaults)

        #expect(try #require(state.configuration).displaySchedule == nil)
    }

    @Test func loadsAdministratorEscapeCodeVerbatim() {
        let defaults = makeDefaults()
        defaults.set(" 0274 ", forKey: "EscapeCode")

        #expect(
            ManagedConfiguration.administratorEscapeCode(from: defaults) ==
                " 0274 "
        )
    }

    @Test func missingOrEmptyAdministratorEscapeCodeDisablesEscape() {
        let defaults = makeDefaults()

        #expect(ManagedConfiguration.administratorEscapeCode(from: defaults) == nil)

        defaults.set("", forKey: "EscapeCode")

        #expect(ManagedConfiguration.administratorEscapeCode(from: defaults) == nil)
    }

    @Test func nonStringAdministratorEscapeCodeDisablesEscape() {
        let defaults = makeDefaults()
        defaults.set(274, forKey: "EscapeCode")

        #expect(ManagedConfiguration.administratorEscapeCode(from: defaults) == nil)
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
