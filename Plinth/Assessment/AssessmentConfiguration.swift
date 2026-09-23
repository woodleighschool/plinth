import AutomaticAssessmentConfiguration
import Foundation

extension AEAssessmentConfiguration {
    convenience init(networkParticipants: [NetworkParticipant]) {
        self.init()
        mainParticipantConfiguration.allowsNetworkAccess = true

        // Background networking does not require restricting which processes may run.
        allowsOnlyParticipantsToRun = false

        for participant in networkParticipants {
            switch participant.identity {
            case let .executable(path):
                let executable = AEAssessmentBinaryExecutable(
                    binaryExecutableURL: URL(filePath: path),
                    teamIdentifier: participant.teamIdentifier
                )
                executable.requiresSignatureValidation = true
                let configuration = AEAssessmentBinaryExecutableConfiguration()
                configuration.allowsNetworkAccess = true
                configuration.isRequired = participant.isRequired
                setConfiguration(configuration, for: executable)
            case let .application(bundleIdentifier):
                let application = AEAssessmentApplication(
                    bundleIdentifier: bundleIdentifier,
                    teamIdentifier: participant.teamIdentifier
                )
                application.requiresSignatureValidation = true
                let configuration = AEAssessmentParticipantConfiguration()
                configuration.allowsNetworkAccess = true
                configuration.isRequired = participant.isRequired
                setConfiguration(configuration, for: application)
            }
        }
    }
}
