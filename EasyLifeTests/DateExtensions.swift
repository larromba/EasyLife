import Foundation

extension Date {
    func minusDays(_ days: Int) -> Date {
        return addingTimeInterval(24.0 * 60.0 * 60.0 * TimeInterval(-days))
    }

    func plusDays(_ days: Int) -> Date {
        return addingTimeInterval(24.0 * 60.0 * 60.0 * TimeInterval(days))
    }
}
