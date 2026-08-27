import AppKit
import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class KioskSession {
    enum Presentation: Equatable {
        case startup
        case maintenance
        case configurationError(String)
        case unavailable
        case browser(BrowserPresentation)
    }

    struct BrowserPresentation: Equatable, Identifiable {
        let id: UUID
        let configuration: ManagedConfiguration
    }

    private enum InactivePresentation {
        case maintenance
        case configurationError(String)
        case unavailable
    }

    nonisolated enum SchedulePhase: Equatable {
        case unmanaged
        case active
        case inactive
    }

    nonisolated struct ScheduleTransition: Equatable {
        let phase: SchedulePhase
        let preparesDisplay: Bool
        let sleepsDisplay: Bool
    }

    private static let idleCheckInterval = Duration.seconds(1)
    private static let retryDelay = Duration.seconds(2)
    private static let maximumBeginAttempts = 3

    private(set) var presentation = Presentation.startup
    private(set) var presentsAdministratorEscape = false

    private let defaults: UserDefaults
    private let assessmentController: AssessmentController
    private let powerController = PowerController()
    private let eventMonitor = LocalEventMonitor()
    private let clock = ContinuousClock()

    private var administratorEscapeCode: String?
    private var exitsForAdministrator = false
    private var configuredConfiguration: ManagedConfiguration?
    private var desiredConfiguration: ManagedConfiguration?
    private var inactivePresentation = InactivePresentation.maintenance
    private var schedulePhase = SchedulePhase.unmanaged
    private var beginAttempts = 0
    private var lastActivity = ContinuousClock.now
    private var retryTask: Task<Void, Never>?
    private var scheduleBoundaryTask: Task<Void, Never>?
    private var displaySleepTask: Task<Void, Never>?
    private var displaySleepRequestID: UUID?

    #if DEBUG
        private let runsUnlocked = CommandLine.arguments.contains("--unlocked")
    #endif

    init(
        defaults: UserDefaults = .standard,
        assessmentController: AssessmentController = AssessmentController()
    ) {
        self.defaults = defaults
        self.assessmentController = assessmentController
        assessmentController.delegate = self
    }

    func run() async {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "unknown"
        Log.app.info("Plinth launched, version \(version, privacy: .public)")

        eventMonitor.start(
            onActivity: { [weak self] in
                self?.lastActivity = .now
            },
            onAdministratorEscape: { [weak self] in
                self?.presentAdministratorEscape() ?? false
            }
        )
        let configurationObserver = ManagedConfigurationObserver(
            defaults: defaults
        ) { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshConfiguration()
            }
        }
        defer {
            withExtendedLifetime(configurationObserver) {}
            eventMonitor.stop()
            retryTask?.cancel()
            scheduleBoundaryTask?.cancel()
            cancelDisplaySleepRequest()
            powerController.allowIdleSleep()
        }

        refreshConfiguration()

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.monitorIdleTimeout()
            }
            group.addTask { [weak self] in
                await self?.monitorScheduleEvents()
            }
            await group.waitForAll()
        }
    }

    private func monitorIdleTimeout() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: Self.idleCheckInterval)
            } catch {
                return
            }

            guard case let .browser(browser) = presentation,
                  browser.configuration.idleResetSeconds > 0,
                  lastActivity.duration(to: clock.now) >= .seconds(
                      browser.configuration.idleResetSeconds
                  )
            else {
                continue
            }

            resetBrowser(using: browser.configuration)
        }
    }

    private func monitorScheduleEvents() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.monitorClockChanges()
            }
            group.addTask { [weak self] in
                await self?.monitorTimeZoneChanges()
            }
            group.addTask { [weak self] in
                await self?.monitorSystemWake()
            }
            await group.waitForAll()
        }
    }

    private func monitorClockChanges() async {
        for await _ in NotificationCenter.default.notifications(
            named: NSNotification.Name.NSSystemClockDidChange
        ) {
            guard !Task.isCancelled else { return }
            reconcileDisplaySchedule(rearmBoundary: true)
        }
    }

    private func monitorTimeZoneChanges() async {
        for await _ in NotificationCenter.default.notifications(
            named: NSNotification.Name.NSSystemTimeZoneDidChange
        ) {
            guard !Task.isCancelled else { return }
            reconcileDisplaySchedule(rearmBoundary: true)
        }
    }

    private func monitorSystemWake() async {
        for await _ in NSWorkspace.shared.notificationCenter.notifications(
            named: NSWorkspace.didWakeNotification
        ) {
            guard !Task.isCancelled else { return }
            reconcileDisplaySchedule(rearmBoundary: true, wokeSystem: true)
        }
    }

    private func refreshConfiguration() {
        guard !exitsForAdministrator else {
            return
        }

        administratorEscapeCode = ManagedConfiguration.administratorEscapeCode(
            from: defaults
        )
        if administratorEscapeCode == nil {
            presentsAdministratorEscape = false
        }

        do {
            switch try ManagedConfiguration.load(from: defaults) {
            case .disabled:
                disableKiosk(for: .maintenance)
            case let .enabled(configuration):
                let changed = configuredConfiguration != configuration
                configuredConfiguration = configuration
                activateKiosk(with: configuration)
                reconcileDisplaySchedule(rearmBoundary: changed)
            }
        } catch {
            Log.configuration.error("Managed configuration is invalid: \(error.localizedDescription, privacy: .public)")
            disableKiosk(for: .configurationError(error.localizedDescription))
        }
    }

    private func reconcileDisplaySchedule(
        rearmBoundary: Bool,
        wokeSystem: Bool = false
    ) {
        guard !exitsForAdministrator,
              let configuration = configuredConfiguration
        else {
            return
        }

        guard let schedule = configuration.displaySchedule else {
            scheduleBoundaryTask?.cancel()
            scheduleBoundaryTask = nil
            schedulePhase = .unmanaged
            cancelDisplaySleepRequest()
            powerController.allowIdleSleep()
            return
        }

        if rearmBoundary || scheduleBoundaryTask == nil {
            armScheduleBoundary(for: schedule)
        }

        let calendar = Calendar.autoupdatingCurrent
        let transition = Self.scheduleTransition(
            isActive: schedule.isActive(at: .now, calendar: calendar),
            from: schedulePhase,
            wokeSystem: wokeSystem
        )
        schedulePhase = transition.phase

        if transition.phase == .active {
            cancelDisplaySleepRequest()
            if transition.preparesDisplay {
                prepareScheduledDisplay()
            }
        } else {
            powerController.allowIdleSleep()
            if transition.sleepsDisplay {
                requestDisplaySleep()
            }
        }
    }

    nonisolated static func scheduleTransition(
        isActive: Bool,
        from phase: SchedulePhase,
        wokeSystem: Bool
    ) -> ScheduleTransition {
        if isActive {
            return ScheduleTransition(
                phase: .active,
                preparesDisplay: phase != .active || wokeSystem,
                sleepsDisplay: false
            )
        }

        return ScheduleTransition(
            phase: .inactive,
            preparesDisplay: false,
            sleepsDisplay: phase == .active && !wokeSystem
        )
    }

    private func activateKiosk(with configuration: ManagedConfiguration) {
        let configurationChanged = desiredConfiguration.map {
            $0.startURL != configuration.startURL ||
                $0.urlPolicy != configuration.urlPolicy ||
                $0.idleResetSeconds != configuration.idleResetSeconds ||
                $0.ephemeralSession != configuration.ephemeralSession
        } ?? true
        desiredConfiguration = configuration
        if configurationChanged {
            beginAttempts = 0
            retryTask?.cancel()
        }

        #if DEBUG
            if runsUnlocked {
                Log.assessment.notice("Running in DEBUG unlocked mode")
                if configurationChanged || !showsBrowser {
                    showBrowser(using: configuration)
                }
                return
            }
        #endif

        if assessmentController.hasSession {
            if configurationChanged, case .browser = presentation {
                showBrowser(using: configuration)
            }
            return
        }

        beginAssessment()
    }

    private func disableKiosk(for inactivePresentation: InactivePresentation) {
        configuredConfiguration = nil
        desiredConfiguration = nil
        self.inactivePresentation = inactivePresentation
        schedulePhase = .unmanaged
        beginAttempts = 0
        retryTask?.cancel()
        scheduleBoundaryTask?.cancel()
        scheduleBoundaryTask = nil
        cancelDisplaySleepRequest()
        powerController.allowIdleSleep()
        presentation = .startup

        #if DEBUG
            if runsUnlocked {
                showInactivePresentation()
                return
            }
        #endif

        if assessmentController.hasSession {
            assessmentController.end()
        } else {
            showInactivePresentation()
        }
    }

    private func armScheduleBoundary(for schedule: DisplaySchedule) {
        scheduleBoundaryTask?.cancel()
        guard let boundary = schedule.nextBoundary(
            after: .now,
            calendar: .autoupdatingCurrent
        ) else {
            scheduleBoundaryTask = nil
            return
        }

        let delay = max(0, boundary.timeIntervalSinceNow)
        scheduleBoundaryTask = Task { @concurrent [weak self] in
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            await self?.scheduleBoundaryReached(schedule)
        }
    }

    private func scheduleBoundaryReached(_ schedule: DisplaySchedule) {
        guard configuredConfiguration?.displaySchedule == schedule else {
            return
        }
        reconcileDisplaySchedule(rearmBoundary: true)
    }

    private func prepareScheduledDisplay() {
        do {
            try powerController.keepDisplayAwake()
        } catch {
            Log.power.error("Could not keep the display awake during scheduled hours: \(error.localizedDescription, privacy: .public)")
            powerController.allowIdleSleep()
        }
    }

    private func requestDisplaySleep() {
        guard displaySleepTask == nil else {
            return
        }

        let requestID = UUID()
        displaySleepRequestID = requestID
        displaySleepTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await powerController.sleepDisplay()
                displaySleepFinished(requestID: requestID, error: nil)
            } catch {
                displaySleepFinished(requestID: requestID, error: error)
            }
        }
    }

    private func displaySleepFinished(requestID: UUID, error: (any Error)?) {
        guard displaySleepRequestID == requestID else {
            return
        }

        displaySleepTask = nil
        displaySleepRequestID = nil
        if let error, schedulePhase == .inactive {
            Log.power.error("Could not sleep the display: \(error.localizedDescription, privacy: .public)")
        } else if error == nil {
            Log.power.info("Display slept outside managed display hours")
        }
    }

    private func cancelDisplaySleepRequest() {
        displaySleepRequestID = nil
        displaySleepTask?.cancel()
        displaySleepTask = nil
    }

    func presentAdministratorEscape() -> Bool {
        guard administratorEscapeCode != nil,
              !exitsForAdministrator
        else {
            return false
        }

        presentsAdministratorEscape = true
        return true
    }

    func dismissAdministratorEscape() {
        guard !exitsForAdministrator else {
            return
        }
        presentsAdministratorEscape = false
    }

    func submitAdministratorEscapeCode(_ code: String) -> Bool {
        guard presentsAdministratorEscape,
              code == administratorEscapeCode
        else {
            return false
        }

        beginAdministratorExit()
        return true
    }

    private func beginAdministratorExit() {
        presentsAdministratorEscape = false
        presentation = .startup
        exitsForAdministrator = true
        administratorEscapeCode = nil
        configuredConfiguration = nil
        desiredConfiguration = nil
        schedulePhase = .unmanaged
        beginAttempts = 0
        retryTask?.cancel()
        scheduleBoundaryTask?.cancel()
        scheduleBoundaryTask = nil
        cancelDisplaySleepRequest()

        if assessmentController.hasSession {
            assessmentController.end()
        } else {
            completeAdministratorExit()
        }
    }

    private func completeAdministratorExit() {
        powerController.allowIdleSleep()
        NSApplication.shared.terminate(nil)
    }

    private func beginAssessment() {
        guard desiredConfiguration != nil,
              !assessmentController.hasSession,
              beginAttempts < Self.maximumBeginAttempts
        else {
            return
        }

        beginAttempts += 1
        presentation = .startup
        assessmentController.begin()
    }

    private func scheduleAssessmentRetry() {
        guard desiredConfiguration != nil,
              beginAttempts < Self.maximumBeginAttempts
        else {
            return
        }

        retryTask?.cancel()
        retryTask = Task { @concurrent [weak self] in
            do {
                try await Task.sleep(for: Self.retryDelay)
            } catch {
                return
            }
            await self?.beginAssessment()
        }
    }

    private func showBrowser(using configuration: ManagedConfiguration) {
        lastActivity = .now
        presentation = .browser(
            BrowserPresentation(id: UUID(), configuration: configuration)
        )
    }

    private func resetBrowser(using configuration: ManagedConfiguration) {
        Log.browser.info("Resetting browser after idle timeout")
        presentation = .startup
        lastActivity = .now

        Task { [weak self] in
            await Task.yield()
            guard let self,
                  desiredConfiguration == configuration
            else {
                return
            }
            showBrowser(using: configuration)
        }
    }

    private var showsBrowser: Bool {
        if case .browser = presentation {
            true
        } else {
            false
        }
    }

    private func showInactivePresentation() {
        switch inactivePresentation {
        case .maintenance:
            presentation = .maintenance
        case let .configurationError(message):
            presentation = .configurationError(message)
        case .unavailable:
            presentation = .unavailable
        }
    }
}

extension KioskSession: AssessmentControllerDelegate {
    func assessmentDidBegin() {
        if exitsForAdministrator {
            assessmentController.end()
            return
        }

        guard let desiredConfiguration else {
            assessmentController.end()
            return
        }

        beginAttempts = 0
        showBrowser(using: desiredConfiguration)
    }

    func assessmentFailedToBegin(with _: any Error) {
        if exitsForAdministrator {
            completeAdministratorExit()
            return
        }

        if desiredConfiguration == nil {
            showInactivePresentation()
        } else {
            presentation = .unavailable
            scheduleAssessmentRetry()
        }
    }

    func assessmentWasInterrupted(with _: any Error) {
        if exitsForAdministrator {
            assessmentController.end()
            return
        }

        if desiredConfiguration == nil {
            showInactivePresentation()
        } else {
            presentation = .unavailable
        }
        assessmentController.end()
    }

    func assessmentDidEnd() {
        if exitsForAdministrator {
            completeAdministratorExit()
            return
        }

        if desiredConfiguration != nil {
            scheduleAssessmentRetry()
        } else {
            showInactivePresentation()
        }
    }
}
