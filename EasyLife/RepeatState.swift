import Foundation

enum RepeatState: Int, DisplayEnum {
    case none
    case daily
    case weekly
    case biweekly
    case triweekly
    case monthly
    case quarterly
    case halfyear
    case yearly
    case bimonthly
    // WARNING: please add new elements here (bottom of list). edit 'display' for ordering

    static var `default`: RepeatState {
        return .none
    }

    static var display: [RepeatState] {
        return [
            .none,
            .daily,
            .weekly,
            .biweekly,
            .triweekly,
            .monthly,
            .bimonthly,
            .quarterly,
            .halfyear,
            .yearly
        ]
    }

    func stringValue() -> String? {
        switch self {
        case .daily:
            return L10n.repeatOptionDaily
        case .weekly:
            return L10n.repeatOptionWeekly
        case .biweekly:
            return L10n.repeatOptionBiWeekly
        case .triweekly:
            return L10n.repeatOptionTriWeekly
        case .monthly:
            return L10n.repeatOptionMonthly
        case .bimonthly:
            return L10n.repeatOptionBiMonthly
        case .quarterly:
            return L10n.repeatOptionQuarterly
        case .halfyear:
            return L10n.dateOptionHalfAYear
        case .yearly:
            return L10n.repeatOptionYearly
        case .none:
            return nil
        }
    }

    func increment(date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfMonth, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfMonth, value: 2, to: date)
        case .triweekly:
            return calendar.date(byAdding: .weekOfMonth, value: 3, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .bimonthly:
            return calendar.date(byAdding: .month, value: 2, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .halfyear:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .none:
            return date
        }
    }
}
