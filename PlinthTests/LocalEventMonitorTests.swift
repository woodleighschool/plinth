import AppKit
@testable import Plinth
import Testing

struct LocalEventMonitorTests {
    @MainActor
    @Test func recognizesAdministratorEscapeChord() {
        #expect(
            LocalEventMonitor.isAdministratorEscape(
                characters: "e",
                modifiers: [.command, .control, .option]
            )
        )
    }

    @MainActor
    @Test func rejectsOtherAdministratorEscapeChords() {
        #expect(
            !LocalEventMonitor.isAdministratorEscape(
                characters: "q",
                modifiers: [.command, .control, .option]
            )
        )
        #expect(
            !LocalEventMonitor.isAdministratorEscape(
                characters: "e",
                modifiers: [.command, .control, .option, .shift]
            )
        )
    }
}
