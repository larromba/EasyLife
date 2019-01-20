import XCTest
import CoreData
@testable import EasyLife

final class ItemTests: XCTestCase {
    func testDateIncrementsPastTodayWhenFarInThePast() {
        // mocks
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "07/01/2016")!.earliest
        let todoItem = MockTodoItem()
        todoItem.date = date
        todoItem.repeats = Int16(RepeatState.monthly.rawValue)

        // sut
        todoItem.incrementDate()

        // test
        guard let incrementedDate = todoItem.date else { return XCTFail("expected Date") }
        XCTAssertGreaterThan(incrementedDate, Date())
    }
}
