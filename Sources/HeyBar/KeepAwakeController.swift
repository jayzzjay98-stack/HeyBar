import Foundation
import IOKit.pwr_mgt

@MainActor
final class KeepAwakeController: ObservableObject {
    typealias TimerFactory = @MainActor (_ interval: TimeInterval, _ handler: @escaping @Sendable () -> Void) -> Timer
    typealias AssertionCreator = @MainActor (_ reason: CFString) -> IOPMAssertionID?
    typealias AssertionReleaser = @MainActor (_ id: IOPMAssertionID) -> Void

    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            persist()
            applyEnabledState()
            syncDurationState(now: nowProvider())
            syncTimerState()
        }
    }

    @Published var usesDurationMode: Bool {
        didSet {
            persist()
            syncDurationState(now: nowProvider(), resetExpiry: true)
            syncTimerState()
        }
    }

    @Published var durationMinutes: Int {
        didSet {
            persist()
            syncDurationState(now: nowProvider(), resetExpiry: true)
            syncTimerState()
        }
    }

    @Published var scheduleEnabled: Bool {
        didSet {
            persist()
            syncDurationState(now: nowProvider(), resetExpiry: true)
            syncTimerState()
        }
    }

    @Published var startDate: Date {
        didSet {
            persist()
        }
    }

    @Published var endDate: Date {
        didSet {
            persist()
        }
    }

    let durationOptions = [0, 1, 5, 10, 15, 30, 45, 60]

    private let defaults: UserDefaults
    private let nowProvider: () -> Date
    private let timerFactory: TimerFactory
    private let createAssertion: () -> IOPMAssertionID?
    private let releaseAssertion: AssertionReleaser

    private var assertionID = IOPMAssertionID()
    private var timer: Timer?

    private static let enabledKey = "keepAwake.enabled"
    private static let usesDurationModeKey = "keepAwake.usesDurationMode"
    private static let durationMinutesKey = "keepAwake.durationMinutes"
    private static let scheduleEnabledKey = "keepAwake.scheduleEnabled"
    private static let startDateKey = "keepAwake.startDate"
    private static let endDateKey = "keepAwake.endDate"
    private static let expiryKey = "keepAwake.expiry"

    init(
        defaults: UserDefaults = .standard,
        reason: CFString = "HeyBar Keep Awake" as CFString,
        nowProvider: @escaping () -> Date = Date.init,
        timerFactory: @escaping TimerFactory = KeepAwakeController.makeRepeatingTimer,
        assertionCreator: @escaping AssertionCreator = KeepAwakeController.makePowerAssertion,
        assertionReleaser: @escaping AssertionReleaser = KeepAwakeController.releasePowerAssertion
    ) {
        self.defaults = defaults
        self.nowProvider = nowProvider
        self.timerFactory = timerFactory
        createAssertion = { assertionCreator(reason) }
        releaseAssertion = assertionReleaser

        let startComponents = DateComponents(calendar: .current, hour: 9, minute: 0)
        let endComponents = DateComponents(calendar: .current, hour: 18, minute: 0)
        let fallbackStart = Calendar.current.date(from: startComponents) ?? Date()
        let fallbackEnd = Calendar.current.date(from: endComponents) ?? Date().addingTimeInterval(60 * 60 * 9)

        isEnabled = defaults.bool(forKey: Self.enabledKey)
        usesDurationMode = defaults.object(forKey: Self.usesDurationModeKey) as? Bool ?? true
        durationMinutes = defaults.object(forKey: Self.durationMinutesKey) as? Int ?? 0
        scheduleEnabled = defaults.object(forKey: Self.scheduleEnabledKey) as? Bool ?? false
        startDate = defaults.object(forKey: Self.startDateKey) as? Date ?? fallbackStart
        endDate = defaults.object(forKey: Self.endDateKey) as? Date ?? fallbackEnd

        applyEnabledState()
        syncDurationState(now: nowProvider())
        syncTimerState()
    }

    var isTomorrow: Bool {
        schedule.wrapsToNextDay
    }

    var isTimerRunning: Bool {
        timer != nil
    }

    var expiryDate: Date? {
        defaults.object(forKey: Self.expiryKey) as? Date
    }

    func durationDescription(for minutes: Int) -> String {
        switch minutes {
        case 0:
            return "Never"
        case 1:
            return "1 minute"
        case 60:
            return "1 hour"
        default:
            return "\(minutes) minutes"
        }
    }

    func tick(now: Date? = nil) {
        let currentNow = now ?? nowProvider()
        handleDurationExpiry(now: currentNow)

        guard scheduleEnabled else { return }

        let window = scheduleWindow(containing: currentNow)
        let shouldEnable = window.contains(currentNow)
        if shouldEnable != isEnabled {
            isEnabled = shouldEnable
        }
    }

    func scheduleWindow(containing date: Date) -> ClosedRange<Date> {
        schedule.window(containing: date)
    }

    private func persist() {
        defaults.set(isEnabled, forKey: Self.enabledKey)
        defaults.set(usesDurationMode, forKey: Self.usesDurationModeKey)
        defaults.set(durationMinutes, forKey: Self.durationMinutesKey)
        defaults.set(scheduleEnabled, forKey: Self.scheduleEnabledKey)
        defaults.set(startDate, forKey: Self.startDateKey)
        defaults.set(endDate, forKey: Self.endDateKey)
    }

    private var schedule: KeepAwakeSchedule {
        KeepAwakeSchedule(startDate: startDate, endDate: endDate)
    }

    private func applyEnabledState() {
        if isEnabled {
            createAssertionIfNeeded()
        } else {
            releaseAssertionIfNeeded()
        }
    }

    private func createAssertionIfNeeded() {
        guard assertionID == 0 else { return }
        if let newAssertion = createAssertion() {
            assertionID = newAssertion
        } else {
            isEnabled = false
        }
    }

    private func releaseAssertionIfNeeded() {
        guard assertionID != 0 else { return }
        releaseAssertion(assertionID)
        assertionID = 0
    }

    private func syncTimerState() {
        timer?.invalidate()
        timer = nil

        guard isEnabled || scheduleEnabled else { return }
        timer = timerFactory(1) { [weak self] in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func syncDurationState(now: Date, resetExpiry: Bool = false) {
        guard isEnabled, usesDurationMode, durationMinutes > 0, !scheduleEnabled else {
            defaults.removeObject(forKey: Self.expiryKey)
            return
        }

        if resetExpiry || expiryDate == nil {
            defaults.set(now.addingTimeInterval(TimeInterval(durationMinutes * 60)), forKey: Self.expiryKey)
        }
    }

    private func handleDurationExpiry(now: Date) {
        guard isEnabled, usesDurationMode, durationMinutes > 0, !scheduleEnabled else {
            defaults.removeObject(forKey: Self.expiryKey)
            return
        }

        guard let expiry = expiryDate else {
            syncDurationState(now: now)
            return
        }

        guard now >= expiry else { return }
        defaults.removeObject(forKey: Self.expiryKey)
        isEnabled = false
    }

    private static func makeRepeatingTimer(interval: TimeInterval, handler: @escaping @Sendable () -> Void) -> Timer {
        // Use .common run loop mode so the timer fires during scroll tracking
        // and other non-default run loop modes.
        let timer = Timer(timeInterval: interval, repeats: true) { _ in handler() }
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    private static func makePowerAssertion(reason: CFString) -> IOPMAssertionID? {
        var newAssertion = IOPMAssertionID()
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &newAssertion
        )
        return result == kIOReturnSuccess ? newAssertion : nil
    }

    private static func releasePowerAssertion(id: IOPMAssertionID) {
        IOPMAssertionRelease(id)
    }
}
