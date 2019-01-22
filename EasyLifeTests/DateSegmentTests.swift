@testable import EasyLife
import XCTest

final class DateSegmentTests: XCTestCase {
    func testDisplay() {
        XCTAssertEqual(DateSegment.display.count, 11)
    }

    // swiftlint:disable cyclomatic_complexity
    func testIncrement() {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!
        for i in 1..<DateSegment.display.count {
            let state = DateSegment.display[i]
            let date2 = state.increment(date: date)
            switch state {
            case .today:
                XCTAssertEqual(dateFormatter.date(from: "21/04/2017")!, date2)
            case .tomorrow:
                XCTAssertEqual(dateFormatter.date(from: "22/04/2017")!, date2)
            case .fewDays:
                XCTAssertEqual(dateFormatter.date(from: "24/04/2017")!, date2)
            case .week:
                XCTAssertEqual(dateFormatter.date(from: "28/04/2017")!, date2)
            case .biweek:
                XCTAssertEqual(dateFormatter.date(from: "05/05/2017")!, date2)
            case .triweek:
                XCTAssertEqual(dateFormatter.date(from: "12/05/2017")!, date2)
            case .month:
                XCTAssertEqual(dateFormatter.date(from: "21/05/2017")!, date2)
            case .quarter:
                XCTAssertEqual(dateFormatter.date(from: "21/07/2017")!, date2)
            case .halfyear:
                XCTAssertEqual(dateFormatter.date(from: "21/10/2017")!, date2)
            case .year:
                XCTAssertEqual(dateFormatter.date(from: "21/04/2018")!, date2)
            case .none:
                break
            }
        }
    }
}
