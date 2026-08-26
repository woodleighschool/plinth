import Foundation
@testable import Plinth
import Testing

struct DisplayScheduleTests {
    private let calendar = makeCalendar(timeZone: "Australia/Melbourne")

    @Test func evaluatesDaytimeScheduleAsHalfOpenInterval() throws {
        let schedule = try DisplaySchedule(
            onTime: "08:00",
            offTime: "17:00",
            dayNames: ["Wednesday"]
        )

        #expect(schedule.isActive(at: date(2026, 8, 26, 8, 0), calendar: calendar))
        #expect(schedule.isActive(at: date(2026, 8, 26, 16, 59), calendar: calendar))
        #expect(!schedule.isActive(at: date(2026, 8, 26, 17, 0), calendar: calendar))
    }

    @Test func overnightScheduleBelongsToItsStartDay() throws {
        let schedule = try DisplaySchedule(
            onTime: "20:00",
            offTime: "06:00",
            dayNames: ["Friday"]
        )

        #expect(schedule.isActive(at: date(2026, 8, 28, 22, 0), calendar: calendar))
        #expect(schedule.isActive(at: date(2026, 8, 29, 5, 59), calendar: calendar))
        #expect(!schedule.isActive(at: date(2026, 8, 29, 20, 0), calendar: calendar))
    }

    @Test func findsCurrentEndAsNextBoundary() throws {
        let schedule = try DisplaySchedule(
            onTime: "08:00",
            offTime: "17:00",
            dayNames: ["Wednesday"]
        )

        #expect(
            schedule.nextBoundary(
                after: date(2026, 8, 26, 12, 0),
                calendar: calendar
            ) == date(2026, 8, 26, 17, 0)
        )
    }

    @Test func findsNextWeekStartAfterCurrentEnd() throws {
        let schedule = try DisplaySchedule(
            onTime: "08:00",
            offTime: "17:00",
            dayNames: ["Wednesday"]
        )

        #expect(
            schedule.nextBoundary(
                after: date(2026, 8, 26, 18, 0),
                calendar: calendar
            ) == date(2026, 9, 2, 8, 0)
        )
    }

    @Test func usesCalendarTimeZone() throws {
        let schedule = try DisplaySchedule(
            onTime: "08:00",
            offTime: "17:00",
            dayNames: ["Wednesday"]
        )
        let instant = Date(timeIntervalSince1970: 1_787_704_200)
        let london = makeCalendar(timeZone: "Europe/London")

        #expect(schedule.isActive(at: instant, calendar: calendar))
        #expect(!schedule.isActive(at: instant, calendar: london))
    }

    @Test func advancesAcrossMissingDaylightSavingTime() throws {
        let schedule = try DisplaySchedule(
            onTime: "02:30",
            offTime: "04:00",
            dayNames: ["Sunday"]
        )

        #expect(!schedule.isActive(at: date(2026, 10, 4, 3, 15), calendar: calendar))
        #expect(schedule.isActive(at: date(2026, 10, 4, 3, 30), calendar: calendar))
    }

    @Test func includesBothOccurrencesOfRepeatedOffTime() throws {
        let schedule = try DisplaySchedule(
            onTime: "01:30",
            offTime: "02:30",
            dayNames: ["Sunday"]
        )
        let formatter = ISO8601DateFormatter()

        let firstOccurrence = try #require(formatter.date(from: "2027-04-03T15:45:00Z"))
        let secondOccurrence = try #require(formatter.date(from: "2027-04-03T16:15:00Z"))
        let afterSecondOccurrence = try #require(formatter.date(from: "2027-04-03T16:45:00Z"))

        #expect(schedule.isActive(at: firstOccurrence, calendar: calendar))
        #expect(schedule.isActive(at: secondOccurrence, calendar: calendar))
        #expect(!schedule.isActive(at: afterSecondOccurrence, calendar: calendar))
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }
}

private func makeCalendar(timeZone identifier: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: identifier)!
    return calendar
}
