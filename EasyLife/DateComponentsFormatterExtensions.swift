import Foundation

extension DateComponentsFormatter {
    static func timeIntervalToString(_ time: TimeInterval, calendar: Calendar = Calendar.current,
                                     unitsStyle: UnitsStyle = .full,
                                     allowedUnits: NSCalendar.Unit = [.year, .month, .day],
                                     collapsesLargestUnit: Bool = true) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = unitsStyle
        formatter.allowedUnits = allowedUnits
        formatter.collapsesLargestUnit = collapsesLargestUnit
        let time = fabs(time) // flip any negative values
        let timeString = formatter.string(from: time)
        return timeString
    }
}
