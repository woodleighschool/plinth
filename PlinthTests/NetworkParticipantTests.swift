import AutomaticAssessmentConfiguration
import Foundation
@testable import Plinth
import Testing

struct NetworkParticipantTests {
    @Test func missingListAllowsNoAdditionalParticipants() throws {
        #expect(try NetworkParticipant.load(from: nil).isEmpty)
        #expect(try NetworkParticipant.load(from: []).isEmpty)
    }

    @Test func loadsExecutableAndApplicationIdentities() throws {
        let participants = try NetworkParticipant.load(from: [
            ["ExecutablePath": "/Library/Example Agent/agent", "TeamIdentifier": "ABCDEFGHIJ", "Required": true],
            ["BundleIdentifier": "org.example.agent"],
        ])

        #expect(participants == [
            NetworkParticipant(identity: .executable(path: "/Library/Example Agent/agent"), teamIdentifier: "ABCDEFGHIJ", isRequired: true),
            NetworkParticipant(identity: .application(bundleIdentifier: "org.example.agent"), teamIdentifier: nil, isRequired: false),
        ])
    }

    @Test(arguments: ["agent", "file:///usr/local/bin/agent", "/", "/usr/local/bin/", "/usr/../bin/agent", "/usr/./bin/agent", "/usr//bin/agent", "/usr/local/*", "/usr/bin/agent\n"])
    func rejectsAmbiguousExecutablePaths(_ path: String) {
        #expect(throws: NetworkParticipant.ValidationError.self) {
            try NetworkParticipant.load(from: [["ExecutablePath": path]])
        }
    }

    @Test func rejectsMalformedEntriesInsteadOfDroppingThem() {
        let invalidValues: [Any] = [
            "org.example.agent",
            ["/usr/local/bin/agent"],
            [[String: Any]()],
            [["ExecutablePath": "/usr/local/bin/agent", "BundleIdentifier": "org.example.agent"]],
            [["BundleIdentifier": "org.example.*"]],
            [["BundleIdentifier": "org.example.agent", "Required": "true"]],
            [["BundleIdentifier": "org.example.agent", "Required": 1]],
            [["BundleIdentifier": "org.example.agent", "TeamIdentifier": ""]],
            [["BundleIdentifier": "org.example.agent", "Require": true]],
            [["ExecutablePath": "/usr/local/bin/agent"], ["ExecutablePath": "/usr/local/bin/agent", "Required": true]],
        ]

        for value in invalidValues {
            #expect(throws: NetworkParticipant.ValidationError.self) {
                try NetworkParticipant.load(from: value)
            }
        }
    }

    @Test @MainActor func translatesToAACWithoutOtherPrivileges() throws {
        let participants = try NetworkParticipant.load(from: [
            ["ExecutablePath": "/Library/Example Agent/agent", "TeamIdentifier": "ABCDEFGHIJ", "Required": true],
            ["BundleIdentifier": "org.example.agent"],
        ])
        let configuration = AEAssessmentConfiguration(networkParticipants: participants)
        let (executable, executableConfiguration) = try #require(configuration.configurationsByBinaryExecutable.first)
        let (application, applicationConfiguration) = try #require(configuration.configurationsByApplication.first)

        #expect(configuration.mainParticipantConfiguration.allowsNetworkAccess)
        #expect(!configuration.allowsOnlyParticipantsToRun)
        #expect(configuration.configurationsByBinaryExecutable.count == 1)
        #expect(configuration.configurationsByApplication.count == 1)
        #expect(executable.binaryExecutableURL == URL(filePath: "/Library/Example Agent/agent"))
        #expect(executable.teamIdentifier == "ABCDEFGHIJ")
        #expect(executable.requiresSignatureValidation)
        #expect(executableConfiguration.allowsNetworkAccess)
        #expect(executableConfiguration.isRequired)
        #expect(application.bundleIdentifier == "org.example.agent")
        #expect(application.teamIdentifier == nil)
        #expect(application.requiresSignatureValidation)
        #expect(applicationConfiguration.allowsNetworkAccess)
        #expect(!applicationConfiguration.isRequired)
    }

    @Test @MainActor func freshConfigurationRemovesOldParticipants() throws {
        let previous = try AEAssessmentConfiguration(networkParticipants: NetworkParticipant.load(from: [
            ["ExecutablePath": "/usr/local/bin/agent"],
        ]))
        let replacement = AEAssessmentConfiguration(networkParticipants: [])

        #expect(previous.configurationsByBinaryExecutable.count == 1)
        #expect(replacement.configurationsByBinaryExecutable.isEmpty)
        #expect(replacement.configurationsByApplication.isEmpty)
    }
}
