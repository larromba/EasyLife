import CoreData
@testable import EasyLife
import XCTest

class RepeatStateTests: XCTestCase {
    func testDisplay() {
        XCTAssertEqual(RepeatState.display.count, 9)
    }

    func testIncrement() {
        // mocks
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!

        // test
        for i in 1..<RepeatState.display.count {
            let state = RepeatState.display[i]
            let date2 = state.increment(date: date)
            switch state {
            case .daily:
                XCTAssertEqual(dateFormatter.date(from: "22/04/2017")!, date2)
            case .weekly:
                XCTAssertEqual(dateFormatter.date(from: "28/04/2017")!, date2)
            case .biweekly:
                XCTAssertEqual(dateFormatter.date(from: "05/05/2017")!, date2)
            case .triweekly:
                XCTAssertEqual(dateFormatter.date(from: "12/05/2017")!, date2)
            case .monthly:
                XCTAssertEqual(dateFormatter.date(from: "21/05/2017")!, date2)
            case .quarterly:
                XCTAssertEqual(dateFormatter.date(from: "21/07/2017")!, date2)
            case .halfyear:
                XCTAssertEqual(dateFormatter.date(from: "21/10/2017")!, date2)
            case .yearly:
                XCTAssertEqual(dateFormatter.date(from: "21/04/2018")!, date2)
            case .none:
                break
            }
        }
    }
}
