import Foundation

enum FocusTime: DisplayEnum {
    case fiveMinutes
    case tenMinutes
    case fifteenMinutes
    case twentyMinutes
    case thirtyMinutes
    case fortyFiveMinutes
    case oneHour
    case none
    case custom(TimeInterval)

    static var `default`: FocusTime = .fifteenMinutes
    static var display: [FocusTime] {
        return [
            fiveMinutes,
            tenMinutes,
            fifteenMinutes,
            twentyMinutes,
            thirtyMinutes,
            fortyFiveMinutes,
            oneHour
        ]
    }

    func row() -> Int {
        FocusTime.display.firstIndex { $0 == self } ?? 0
    }

    func displayValue() -> String {
        switch self {
        case .fiveMinutes: return L10n.focusTime5m
        case .tenMinutes: return L10n.focusTime10m
        case .fifteenMinutes: return L10n.focusTime15m
        case .twentyMinutes: return L10n.focusTime20m
        case .thirtyMinutes: return L10n.focusTime30m
        case .fortyFiveMinutes: return L10n.focusTime45m
        case .oneHour: return L10n.focusTime1h
        case .none, .custom:
            assertionFailure("should not be displayed")
            return ""
        }
    }

    func timeValue() -> TimeInterval {
        switch self {
        case .none: return 0.0
        case .fiveMinutes: return 5.0 * 60.0
        case .tenMinutes: return 10.0 * 60.0
        case .fifteenMinutes: return 15.0 * 60.0
        case .twentyMinutes: return 20.0 * 60.0
        case .thirtyMinutes: return 30.0 * 60.0
        case .fortyFiveMinutes: return 45.0 * 60.0
        case .oneHour: return 60.0 * 60.0
        case .custom(let interval): return interval
        }

    }

    func timeStringValue() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let date = Date().earliest.addingTimeInterval(timeValue())
        return dateFormatter.string(from: date)
    }
}

// MARK: - Equatable

extension FocusTime: Equatable {
    static func == (lhs: FocusTime, rhs: FocusTime) -> Bool {
        switch (lhs, rhs) {
        case (.fiveMinutes, .fiveMinutes),
             (.tenMinutes, .tenMinutes),
             (.fifteenMinutes, .fifteenMinutes),
             (.twentyMinutes, .twentyMinutes),
             (.thirtyMinutes, .thirtyMinutes),
             (.fortyFiveMinutes, .fortyFiveMinutes),
             (.oneHour, .oneHour),
             (.none, .none):
            return true
        case let (.custom(timeA), .custom(timeB)):
            return timeA == timeB
        default:
            return false
        }
    }
}
