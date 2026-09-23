import AutomaticAssessmentConfiguration
import Foundation
import OSLog

@MainActor
protocol AssessmentControllerDelegate: AnyObject {
    func assessmentDidBegin()
    func assessmentFailedToBegin(with error: Error)
    func assessmentWasInterrupted(with error: Error)
    func assessmentDidEnd()
    func assessmentWillUpdate()
    func assessmentDidUpdate()
    func assessmentFailedToUpdate(with error: Error)
}

@MainActor
final class AssessmentController: NSObject {
    private enum Phase {
        case idle
        case starting([NetworkParticipant])
        case active([NetworkParticipant])
        case updating(previous: [NetworkParticipant], requested: [NetworkParticipant])
        case ending
    }

    weak var delegate: AssessmentControllerDelegate?

    private let makeSession: (AEAssessmentConfiguration) -> AEAssessmentSession
    private var session: AEAssessmentSession?
    private var phase = Phase.idle
    private var desiredParticipants: [NetworkParticipant]?

    init(
        makeSession: @escaping (AEAssessmentConfiguration) -> AEAssessmentSession = AEAssessmentSession.init(configuration:)
    ) {
        self.makeSession = makeSession
        super.init()
    }

    var hasSession: Bool {
        session != nil
    }

    func begin(networkParticipants: [NetworkParticipant]) {
        guard session == nil else {
            return
        }

        desiredParticipants = networkParticipants
        phase = .starting(networkParticipants)
        let session = makeSession(AEAssessmentConfiguration(networkParticipants: networkParticipants))
        session.delegate = self
        self.session = session

        Log.assessment.info("Beginning assessment session")
        session.begin()
    }

    func update(networkParticipants: [NetworkParticipant]) {
        guard desiredParticipants.map(Set.init) != Set(networkParticipants) else {
            return
        }
        desiredParticipants = networkParticipants
        reconcile()
    }

    func end() {
        desiredParticipants = nil
        guard session != nil else {
            delegate?.assessmentDidEnd()
            return
        }
        reconcile()
    }

    private func reconcile() {
        // AAC operations complete through delegate callbacks. Coalesce profile changes
        // while one is in flight, including an exit requested during begin or update.
        guard let session, case let .active(applied) = phase else {
            return
        }
        guard let desiredParticipants else {
            phase = .ending
            Log.assessment.info("Ending assessment session")
            session.end()
            return
        }
        guard Set(applied) != Set(desiredParticipants) else {
            delegate?.assessmentDidUpdate()
            return
        }

        phase = .updating(previous: applied, requested: desiredParticipants)
        delegate?.assessmentWillUpdate()
        Log.assessment.info("Updating assessment network participants")
        session.update(to: AEAssessmentConfiguration(networkParticipants: desiredParticipants))
    }
}

extension AssessmentController: AEAssessmentSessionDelegate {
    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        guard session === self.session, case let .starting(participants) = phase else {
            return
        }

        phase = .active(participants)
        Log.assessment.info("Assessment session began")
        if desiredParticipants != nil {
            delegate?.assessmentDidBegin()
        }
        reconcile()
    }

    func assessmentSession(
        _ session: AEAssessmentSession,
        failedToBeginWithError error: any Error
    ) {
        guard session === self.session else {
            return
        }

        self.session = nil
        phase = .idle
        desiredParticipants = nil
        Log.assessment.error("Assessment session failed to begin: \(error.localizedDescription, privacy: .public)")
        delegate?.assessmentFailedToBegin(with: error)
    }

    func assessmentSession(
        _ session: AEAssessmentSession,
        wasInterruptedWithError error: any Error
    ) {
        guard session === self.session else {
            return
        }

        Log.assessment.error("Assessment session was interrupted: \(error.localizedDescription, privacy: .public)")
        phase = .ending
        desiredParticipants = nil
        delegate?.assessmentWasInterrupted(with: error)
        session.end()
    }

    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        guard session === self.session else {
            return
        }

        self.session = nil
        phase = .idle
        desiredParticipants = nil
        Log.assessment.info("Assessment session ended")
        delegate?.assessmentDidEnd()
    }

    func assessmentSessionDidUpdate(_ session: AEAssessmentSession) {
        guard session === self.session, case let .updating(_, requested) = phase else {
            return
        }

        phase = .active(requested)
        Log.assessment.info("Assessment network participants updated")
        reconcile()
    }

    func assessmentSession(
        _ session: AEAssessmentSession,
        failedToUpdateTo _: AEAssessmentConfiguration,
        error: any Error
    ) {
        guard session === self.session, case let .updating(previous, requested) = phase else {
            return
        }

        phase = .active(previous)
        Log.assessment.error("Could not update assessment network participants: \(error.localizedDescription, privacy: .public)")
        if desiredParticipants.map(Set.init) == Set(requested) {
            delegate?.assessmentFailedToUpdate(with: error)
        } else {
            reconcile()
        }
    }
}
