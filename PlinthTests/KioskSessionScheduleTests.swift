@testable import Plinth
import Testing

struct KioskSessionScheduleTests {
    @Test func launchOutsideHoursDoesNotSleepDisplay() {
        let transition = KioskSession.scheduleTransition(
            isActive: false,
            from: .unmanaged,
            wokeSystem: false
        )

        #expect(transition.phase == .inactive)
        #expect(!transition.preparesDisplay)
        #expect(!transition.sleepsDisplay)
    }

    @Test func offBoundarySleepsDisplayOnce() {
        let transition = KioskSession.scheduleTransition(
            isActive: false,
            from: .active,
            wokeSystem: false
        )

        #expect(transition.phase == .inactive)
        #expect(transition.sleepsDisplay)
    }

    @Test func laterInactiveReconciliationDoesNotSleepDisplayAgain() {
        let transition = KioskSession.scheduleTransition(
            isActive: false,
            from: .inactive,
            wokeSystem: false
        )

        #expect(!transition.sleepsDisplay)
    }

    @Test func systemWakeAcrossOffBoundaryDoesNotSleepDisplay() {
        let transition = KioskSession.scheduleTransition(
            isActive: false,
            from: .active,
            wokeSystem: true
        )

        #expect(transition.phase == .inactive)
        #expect(!transition.sleepsDisplay)
    }

    @Test func activeHoursPrepareDisplayOnEntryAndSystemWake() {
        let entry = KioskSession.scheduleTransition(
            isActive: true,
            from: .inactive,
            wokeSystem: false
        )
        let systemWake = KioskSession.scheduleTransition(
            isActive: true,
            from: .active,
            wokeSystem: true
        )

        #expect(entry.preparesDisplay)
        #expect(systemWake.preparesDisplay)
        #expect(!entry.sleepsDisplay)
        #expect(!systemWake.sleepsDisplay)
    }
}
