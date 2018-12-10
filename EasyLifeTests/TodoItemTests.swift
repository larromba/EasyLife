import XCTest
import CoreData
@testable import EasyLife

class TodoItemTests: XCTestCase {
    func testDateIncrementsPastTodayWhenFarInThePast() {
        // mocks
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "07/01/2016")!.earliest
        let todoItem = MockTodoItem()

        // prepare
        todoItem._date = date
        todoItem._repeats = Int16(RepeatState.monthly.rawValue)

        // test
        todoItem.incrementDate()
        guard let incrementedDate = todoItem.date else {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(incrementedDate, Date())
    }
}
