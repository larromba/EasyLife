import Foundation

// swiftlint:disable cyclomatic_complexity
enum DateSegment: Int, DisplayEnum {
    case none
    case today
    case tomorrow
    case fewDays
    case week
    case biweek
    case triweek
    case month
    case quarter
    case halfyear
    case year
    // WARNING: please add new elements here. edit display for ordering

    static var display: [DateSegment] {
        return [
            .none,
            .today,
            .tomorrow,
            .fewDays,
            .week,
            .biweek,
            .triweek,
            .month,
            .quarter,
            .halfyear,
            .year
        ]
    }

    func stringValue() -> String? {
        switch self {
        case .today:
            return L10n.dateOptionToday
        case .tomorrow:
            return L10n.dateOptionTomorow
        case .fewDays:
            return L10n.dateOptionAFewDays
        case .week:
            return L10n.dateOptionNextWeek
        case .biweek:
            return L10n.dateOption2Weeks
        case .triweek:
            return L10n.dateOption3Weeks
        case .month:
            return L10n.dateOption1Month
        case .quarter:
            return L10n.dateOptionAFewMonths
        case .halfyear:
            return L10n.dateOptionHalfAYear
        case .year:
            return L10n.dateOptionNextYear
        case .none:
            return nil
        }
    }

    func increment(date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .fewDays:
            return calendar.date(byAdding: .day, value: 3, to: date)
        case .week:
            return calendar.date(byAdding: .weekOfMonth, value: 1, to: date)
        case .biweek:
            return calendar.date(byAdding: .weekOfMonth, value: 2, to: date)
        case .triweek:
            return calendar.date(byAdding: .weekOfMonth, value: 3, to: date)
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarter:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .halfyear:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .year:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .today:
            return date
        case .none:
            return nil
        }
    }
}
