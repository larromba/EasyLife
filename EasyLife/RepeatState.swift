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
    // WARNING: please add new elements here. edit display for ordering

    static var display: [RepeatState] {
        return [
            .none,
            .daily,
            .weekly,
            .biweekly,
            .triweekly,
            .monthly,
            .quarterly,
            .halfyear,
            .yearly
        ]
    }

    func stringValue() -> String? {
        switch self {
        case .daily:
            return "daily".localized
        case .weekly:
            return "weekly".localized
        case .biweekly:
            return "bi-weekly".localized
        case .triweekly:
            return "tri-weekly".localized
        case .monthly:
            return "monthly".localized
        case .quarterly:
            return "quarterly".localized
        case .halfyear:
            return "every 6 months".localized
        case .yearly:
            return "yearly".localized
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
