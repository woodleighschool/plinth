import AutomaticAssessmentConfiguration
import Foundation
import OSLog

@MainActor
protocol AssessmentControllerDelegate: AnyObject {
    func assessmentDidBegin()
    func assessmentFailedToBegin(with error: Error)
    func assessmentWasInterrupted(with error: Error)
    func assessmentDidEnd()
}

@MainActor
final class AssessmentController: NSObject {
    weak var delegate: AssessmentControllerDelegate?

    private var session: AEAssessmentSession?

    var hasSession: Bool {
        session != nil
    }

    func begin() {
        guard session == nil else {
            return
        }

        let configuration = AEAssessmentConfiguration()
        configuration.mainParticipantConfiguration.allowsNetworkAccess = true

        let session = AEAssessmentSession(configuration: configuration)
        session.delegate = self
        self.session = session

        Log.assessment.info("Beginning assessment session")
        session.begin()
    }

    func end() {
        guard let session else {
            delegate?.assessmentDidEnd()
            return
        }

        Log.assessment.info("Ending assessment session")
        session.end()
    }
}

extension AssessmentController: AEAssessmentSessionDelegate {
    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        guard session === self.session else {
            return
        }

        Log.assessment.info("Assessment session began")
        delegate?.assessmentDidBegin()
    }

    func assessmentSession(
        _ session: AEAssessmentSession,
        failedToBeginWithError error: any Error
    ) {
        guard session === self.session else {
            return
        }

        self.session = nil
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
        delegate?.assessmentWasInterrupted(with: error)
    }

    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        guard session === self.session else {
            return
        }

        self.session = nil
        Log.assessment.info("Assessment session ended")
        delegate?.assessmentDidEnd()
    }
}
