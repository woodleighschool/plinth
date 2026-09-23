import AutomaticAssessmentConfiguration
import Foundation
@testable import Plinth
import Testing

@MainActor
struct AssessmentControllerTests {
    @Test func coalescesChangesDuringBeginAndUpdate() throws {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let delegate = RecordingAssessmentDelegate()
        let controller = AssessmentController { _ in session }
        controller.delegate = delegate
        let first = try participants("first")
        let latest = try participants("latest")

        controller.begin(networkParticipants: [])
        controller.update(networkParticipants: first)
        #expect(session.updates.isEmpty)
        #expect(delegate.begins == 0)

        controller.assessmentSessionDidBegin(session)
        #expect(delegate.begins == 1)
        #expect(session.updates.count == 1)
        controller.update(networkParticipants: [])
        controller.update(networkParticipants: latest)
        #expect(session.updates.count == 1)

        controller.assessmentSessionDidUpdate(session)
        #expect(session.updates.count == 2)
        #expect(session.updates.last?.configurationsByBinaryExecutable.keys.first?.binaryExecutableURL.path == "/usr/local/bin/latest")
        #expect(delegate.updates == 0)
        controller.assessmentSessionDidUpdate(session)
        #expect(delegate.updates == 1)
    }

    @Test func reorderedParticipantsDoNotUpdateSession() throws {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let controller = AssessmentController { _ in session }
        let entries = try participants("first") + participants("second")
        controller.begin(networkParticipants: entries)
        controller.assessmentSessionDidBegin(session)
        controller.update(networkParticipants: entries.reversed())

        #expect(session.updates.isEmpty)
    }

    @Test func failedUpdateKeepsSessionAndCanBeCorrected() throws {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let delegate = RecordingAssessmentDelegate()
        let controller = AssessmentController { _ in session }
        controller.delegate = delegate
        controller.begin(networkParticipants: [])
        controller.assessmentSessionDidBegin(session)

        let invalid = try participants("unavailable")
        controller.update(networkParticipants: invalid)
        let update = try #require(session.updates.last)
        controller.assessmentSession(session, failedToUpdateTo: update, error: TestError.unavailable)
        controller.update(networkParticipants: invalid)

        #expect(controller.hasSession)
        #expect(session.ends == 0)
        #expect(session.updates.count == 1)
        #expect(delegate.failures == 1)

        controller.update(networkParticipants: [])
        #expect(session.updates.count == 1)
        #expect(delegate.updates == 2)
    }

    @Test func newerProfileIsAppliedAfterAnEarlierUpdateFails() throws {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let delegate = RecordingAssessmentDelegate()
        let controller = AssessmentController { _ in session }
        controller.delegate = delegate
        controller.begin(networkParticipants: [])
        controller.assessmentSessionDidBegin(session)
        try controller.update(networkParticipants: participants("unavailable"))
        let update = try #require(session.updates.last)
        try controller.update(networkParticipants: participants("replacement"))
        controller.assessmentSession(session, failedToUpdateTo: update, error: TestError.unavailable)

        #expect(delegate.failures == 0)
        #expect(session.updates.count == 2)
        #expect(session.updates.last?.configurationsByBinaryExecutable.keys.first?.binaryExecutableURL.path == "/usr/local/bin/replacement")
    }

    @Test func exitDuringBeginWaitsForCallbackAndDoesNotShowBrowser() {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let delegate = RecordingAssessmentDelegate()
        let controller = AssessmentController { _ in session }
        controller.delegate = delegate
        controller.begin(networkParticipants: [])
        controller.end()
        #expect(session.ends == 0)

        controller.assessmentSessionDidBegin(session)
        #expect(delegate.begins == 0)
        #expect(session.ends == 1)
        controller.assessmentSessionDidEnd(session)
        #expect(!controller.hasSession)
    }

    @Test func exitDuringUpdateWaitsForCallback() throws {
        let session = SimulatedAssessmentSession(configuration: AEAssessmentConfiguration())
        let controller = AssessmentController { _ in session }
        controller.begin(networkParticipants: [])
        controller.assessmentSessionDidBegin(session)
        try controller.update(networkParticipants: participants("agent"))
        controller.end()
        #expect(session.ends == 0)

        controller.assessmentSessionDidUpdate(session)
        #expect(session.ends == 1)
        controller.assessmentSessionDidEnd(session)
        #expect(!controller.hasSession)
    }

    private func participants(_ name: String) throws -> [NetworkParticipant] {
        try NetworkParticipant.load(from: [["ExecutablePath": "/usr/local/bin/\(name)"]])
    }
}

private enum TestError: Error {
    case unavailable
}

@MainActor
private final class SimulatedAssessmentSession: AEAssessmentSession {
    var updates: [AEAssessmentConfiguration] = []
    var ends = 0

    override func begin() {}

    override func update(to configuration: AEAssessmentConfiguration) {
        updates.append(configuration)
    }

    override func end() {
        ends += 1
    }
}

@MainActor
private final class RecordingAssessmentDelegate: AssessmentControllerDelegate {
    var begins = 0
    var updates = 0
    var failures = 0

    func assessmentDidBegin() {
        begins += 1
    }

    func assessmentDidUpdate() {
        updates += 1
    }

    func assessmentFailedToUpdate(with _: any Error) {
        failures += 1
    }

    func assessmentWillUpdate() {}
    func assessmentDidEnd() {}
    func assessmentFailedToBegin(with _: any Error) {}
    func assessmentWasInterrupted(with _: any Error) {}
}
