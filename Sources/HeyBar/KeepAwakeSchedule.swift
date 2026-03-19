import Foundation

struct KeepAwakeSchedule {
    let startDate: Date
    let endDate: Date
    let calendar: Calendar

    init(startDate: Date, endDate: Date, calendar: Calendar = .current) {
        self.startDate = startDate
        self.endDate = endDate
        self.calendar = calendar
    }

    var wrapsToNextDay: Bool {
        let startHour = calendar.component(.hour, from: startDate)
        let startMinute = calendar.component(.minute, from: startDate)
        let endHour = calendar.component(.hour, from: endDate)
        let endMinute = calendar.component(.minute, from: endDate)

        return endHour < startHour || (endHour == startHour && endMinute <= startMinute)
    }

    func window(containing date: Date) -> ClosedRange<Date> {
        let startToday = time(on: date, matching: startDate)
        let endToday = time(on: date, matching: endDate)

        guard wrapsToNextDay else {
            return startToday...endToday
        }

        if date >= startToday {
            let adjustedEnd = calendar.date(byAdding: .day, value: 1, to: endToday) ?? endToday
            return startToday...adjustedEnd
        }

        let adjustedStart = calendar.date(byAdding: .day, value: -1, to: startToday) ?? startToday
        return adjustedStart...endToday
    }

    private func time(on referenceDate: Date, matching templateDate: Date) -> Date {
        calendar.date(
            bySettingHour: calendar.component(.hour, from: templateDate),
            minute: calendar.component(.minute, from: templateDate),
            second: 0,
            of: referenceDate
        ) ?? referenceDate
    }
}
