import Foundation

protocol SimpleDatePickerViewStating {
    var date: Date? { get }
    var rowCount: Int { get }
    var numOfComponents: Int { get }

    func item(for row: Int) -> DateSegment
    func date(for row: Int) -> Date?
}

struct SimpleDatePickerViewState: SimpleDatePickerViewStating {
    let date: Date?
    var rowCount: Int {
        return rows.count
    }
    let numOfComponents: Int = 1

    private let rows: [DateSegment]

    init(date: Date?, rows: [DateSegment]) {
        self.date = date
        self.rows = rows
    }

    func item(for row: Int) -> DateSegment {
        return rows[row]
    }

    func date(for row: Int) -> Date? {
        if let date = date {
            return item(for: row).increment(date: date)
        } else {
            return nil
        }
    }
}
