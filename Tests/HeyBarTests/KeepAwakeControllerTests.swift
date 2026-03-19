import XCTest
@testable import HeyBar

@MainActor
final class KeepAwakeControllerTests: XCTestCase {
    func testEnablingStartsTimerAndCreatesExpiry() {
        let defaults = makeDefaults()
        let now = Date(timeIntervalSinceReferenceDate: 10_000)
        let controller = KeepAwakeController(
            defaults: defaults,
            nowProvider: { now },
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        controller.durationMinutes = 5
        controller.isEnabled = true

        XCTAssertTrue(controller.isTimerRunning)
        XCTAssertEqual(controller.expiryDate, now.addingTimeInterval(300))
    }

    func testDisablingStopsTimerAndClearsExpiry() {
        let defaults = makeDefaults()
        let now = Date(timeIntervalSinceReferenceDate: 20_000)
        let controller = KeepAwakeController(
            defaults: defaults,
            nowProvider: { now },
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        controller.durationMinutes = 5
        controller.isEnabled = true
        controller.isEnabled = false

        XCTAssertFalse(controller.isTimerRunning)
        XCTAssertNil(controller.expiryDate)
    }

    func testTickDisablesKeepAwakeWhenDurationExpires() {
        let defaults = makeDefaults()
        let start = Date(timeIntervalSinceReferenceDate: 30_000)
        var now = start
        let controller = KeepAwakeController(
            defaults: defaults,
            nowProvider: { now },
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        controller.durationMinutes = 1
        controller.isEnabled = true
        now = start.addingTimeInterval(61)

        controller.tick(now: now)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertNil(controller.expiryDate)
    }

    func testScheduleWindowSupportsOvernightRange() {
        let defaults = makeDefaults()
        let controller = KeepAwakeController(
            defaults: defaults,
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        let calendar = Calendar(identifier: .gregorian)
        controller.startDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 22, minute: 0))!
        controller.endDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 6, minute: 0))!
        let sample = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 1, minute: 0))!

        let window = controller.scheduleWindow(containing: sample)

        XCTAssertTrue(window.contains(sample))
    }

    func testScheduleWindowExcludesTimeBeforeOvernightStart() {
        let defaults = makeDefaults()
        let controller = KeepAwakeController(
            defaults: defaults,
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        let calendar = Calendar(identifier: .gregorian)
        controller.startDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 22, minute: 0))!
        controller.endDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 6, minute: 0))!
        let sample = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 21, minute: 0))!

        let window = controller.scheduleWindow(containing: sample)

        XCTAssertFalse(window.contains(sample))
    }

    func testScheduleWindowSupportsSameDayRange() {
        let defaults = makeDefaults()
        let controller = KeepAwakeController(
            defaults: defaults,
            timerFactory: { _, _ in Timer(timeInterval: 1, repeats: true) { _ in } },
            assertionCreator: { _ in 1 },
            assertionReleaser: { _ in }
        )

        let calendar = Calendar(identifier: .gregorian)
        controller.startDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 9, minute: 0))!
        controller.endDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 19, hour: 18, minute: 0))!
        let inside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 12, minute: 0))!
        let outside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 20, hour: 20, minute: 0))!

        let window = controller.scheduleWindow(containing: inside)

        XCTAssertTrue(window.contains(inside))
        XCTAssertFalse(window.contains(outside))
        XCTAssertFalse(controller.isTomorrow)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "KeepAwakeControllerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
