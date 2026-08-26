import Foundation
import IOKit.pwr_mgt
import OSLog

@MainActor
final class PowerController {
    enum PowerError: Error, LocalizedError {
        case assertion(String, IOReturn)
        case displaySleepLaunch(String)
        case displaySleepFailed(Int32, String)
        case displaySleepTimedOut

        var errorDescription: String? {
            switch self {
            case let .assertion(operation, result):
                "\(operation) failed with IOReturn 0x\(String(UInt32(bitPattern: result), radix: 16))."
            case let .displaySleepLaunch(message):
                "Could not launch pmset: \(message)"
            case let .displaySleepFailed(status, message):
                "pmset displaysleepnow exited with status \(status): \(message)"
            case .displaySleepTimedOut:
                "pmset displaysleepnow did not finish within five seconds."
            }
        }
    }

    private final class Assertion {
        let id: IOPMAssertionID

        init(type: CFString, reason: CFString, operation: String) throws {
            var id = IOPMAssertionID(kIOPMNullAssertionID)
            let result = IOPMAssertionCreateWithName(
                type,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &id
            )
            guard result == kIOReturnSuccess else {
                throw PowerError.assertion(operation, result)
            }
            self.id = id
        }

        deinit {
            let result = IOPMAssertionRelease(id)
            if result != kIOReturnSuccess {
                Log.power.error("Could not release power assertion: IOReturn 0x\(String(UInt32(bitPattern: result), radix: 16), privacy: .public)")
            }
        }
    }

    private final class ProcessBox: @unchecked Sendable {
        let process = Process()
    }

    private var systemSleepAssertion: Assertion?
    private var displaySleepAssertion: Assertion?

    func enableScheduling() throws {
        guard systemSleepAssertion == nil else {
            return
        }

        systemSleepAssertion = try Assertion(
            type: kIOPMAssertPreventUserIdleSystemSleep as CFString,
            reason: "Plinth managed display scheduling" as CFString,
            operation: "Preventing idle system sleep"
        )
        Log.power.info("Managed display scheduling enabled")
    }

    func disableScheduling() {
        displaySleepAssertion = nil
        systemSleepAssertion = nil
    }

    func wakeDisplay() throws {
        var userActivityAssertion = IOPMAssertionID(kIOPMNullAssertionID)
        let result = IOPMAssertionDeclareUserActivity(
            "Plinth managed display schedule" as CFString,
            kIOPMUserActiveLocal,
            &userActivityAssertion
        )
        guard result == kIOReturnSuccess else {
            throw PowerError.assertion("Waking the display", result)
        }
        defer {
            if userActivityAssertion != IOPMAssertionID(kIOPMNullAssertionID) {
                IOPMAssertionRelease(userActivityAssertion)
            }
        }

        if displaySleepAssertion == nil {
            displaySleepAssertion = try Assertion(
                type: kIOPMAssertPreventUserIdleDisplaySleep as CFString,
                reason: "Plinth managed display hours" as CFString,
                operation: "Preventing idle display sleep"
            )
        }
        Log.power.info("Display awake for managed display hours")
    }

    func allowDisplaySleep() {
        displaySleepAssertion = nil
    }

    nonisolated func sleepDisplay() async throws {
        let processBox = ProcessBox()
        let standardError = Pipe()
        processBox.process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        processBox.process.arguments = ["displaysleepnow"]
        processBox.process.standardError = standardError

        do {
            try processBox.process.run()
        } catch {
            throw PowerError.displaySleepLaunch(error.localizedDescription)
        }

        let status = try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: Int32.self) { group in
                group.addTask {
                    processBox.process.waitUntilExit()
                    return processBox.process.terminationStatus
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(5))
                    throw PowerError.displaySleepTimedOut
                }

                defer {
                    group.cancelAll()
                    if processBox.process.isRunning {
                        processBox.process.terminate()
                    }
                }

                guard let status = try await group.next() else {
                    throw PowerError.displaySleepTimedOut
                }
                return status
            }
        } onCancel: {
            if processBox.process.isRunning {
                processBox.process.terminate()
            }
        }

        guard processBox.process.terminationReason == .exit, status == 0 else {
            let data = try standardError.fileHandleForReading.readToEnd() ?? Data()
            let message = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw PowerError.displaySleepFailed(status, message)
        }
    }
}
