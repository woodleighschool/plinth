import Foundation

nonisolated struct DisplaySchedule: Equatable, Sendable {
    enum ValidationError: Error {
        case invalidTime
        case invalidDays
        case identicalTimes
    }

    enum Weekday: String, CaseIterable, Hashable, Sendable {
        case sunday = "Sunday"
        case monday = "Monday"
        case tuesday = "Tuesday"
        case wednesday = "Wednesday"
        case thursday = "Thursday"
        case friday = "Friday"
        case saturday = "Saturday"

        static let weekdays: Set<Self> = [
            .monday,
            .tuesday,
            .wednesday,
            .thursday,
            .friday,
        ]

        init?(calendarWeekday: Int) {
            switch calendarWeekday {
            case 1: self = .sunday
            case 2: self = .monday
            case 3: self = .tuesday
            case 4: self = .wednesday
            case 5: self = .thursday
            case 6: self = .friday
            case 7: self = .saturday
            default: return nil
            }
        }
    }

    struct Time: Equatable, Sendable {
        let hour: Int
        let minute: Int

        fileprivate init(_ value: String) throws {
            let bytes = Array(value.utf8)
            guard bytes.count == 5,
                  bytes[2] == 58,
                  bytes.enumerated().allSatisfy({ index, byte in
                      index == 2 || (48 ... 57).contains(byte)
                  })
            else {
                throw ValidationError.invalidTime
            }

            let hour = Int(bytes[0] - 48) * 10 + Int(bytes[1] - 48)
            let minute = Int(bytes[3] - 48) * 10 + Int(bytes[4] - 48)
            guard (0 ... 23).contains(hour), (0 ... 59).contains(minute) else {
                throw ValidationError.invalidTime
            }

            self.hour = hour
            self.minute = minute
        }

        fileprivate var minutesSinceMidnight: Int {
            hour * 60 + minute
        }
    }

    let onTime: Time
    let offTime: Time
    let days: Set<Weekday>

    init(onTime: String, offTime: String, dayNames: [String]?) throws {
        let onTime = try Time(onTime)
        let offTime = try Time(offTime)
        guard onTime != offTime else {
            throw ValidationError.identicalTimes
        }

        let days: Set<Weekday>
        if let dayNames {
            let parsed = dayNames.compactMap(Weekday.init(rawValue:))
            guard !dayNames.isEmpty, parsed.count == dayNames.count else {
                throw ValidationError.invalidDays
            }
            days = Set(parsed)
        } else {
            days = Weekday.weekdays
        }

        self.onTime = onTime
        self.offTime = offTime
        self.days = days
    }

    func isActive(at date: Date, calendar: Calendar) -> Bool {
        let today = calendar.startOfDay(for: date)

        for dayOffset in [-1, 0] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let interval = interval(startingOn: day, calendar: calendar),
                  date >= interval.start,
                  date < interval.end
            else {
                continue
            }
            return true
        }

        return false
    }

    func nextBoundary(after date: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: date)
        var result: Date?

        for dayOffset in -1 ... 7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today),
                  let interval = interval(startingOn: day, calendar: calendar)
            else {
                continue
            }

            for boundary in [interval.start, interval.end] where boundary > date {
                if let existing = result {
                    if boundary < existing {
                        result = boundary
                    }
                } else {
                    result = boundary
                }
            }
        }

        return result
    }

    private func interval(startingOn day: Date, calendar: Calendar) -> DateInterval? {
        guard let weekday = Weekday(
            calendarWeekday: calendar.component(.weekday, from: day)
        ), days.contains(weekday),
        let start = date(on: day, at: onTime, repeatedTimePolicy: .first, calendar: calendar)
        else {
            return nil
        }

        let endsNextDay = offTime.minutesSinceMidnight < onTime.minutesSinceMidnight
        guard let endDay = endsNextDay
            ? calendar.date(byAdding: .day, value: 1, to: day)
            : day,
            let end = date(
                on: endDay,
                at: offTime,
                repeatedTimePolicy: .last,
                calendar: calendar
            )
        else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }

    private func date(
        on day: Date,
        at time: Time,
        repeatedTimePolicy: Calendar.RepeatedTimePolicy,
        calendar: Calendar
    ) -> Date? {
        calendar.nextDate(
            after: calendar.startOfDay(for: day).addingTimeInterval(-1),
            matching: DateComponents(hour: time.hour, minute: time.minute),
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: repeatedTimePolicy,
            direction: .forward
        )
    }
}
