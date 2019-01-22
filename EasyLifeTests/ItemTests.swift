@testable import EasyLife
import XCTest

final class ItemTests: XCTestCase {
    private final class MockTodoItem: TodoItem {
        private var _name: String?
        override var name: String? {
            get { return _name }
            set { _name = newValue }
        }
        private var _notes: String?
        override var notes: String? {
            get { return _notes }
            set { _notes = newValue }
        }
        private var _date: Date?
        override var date: Date? {
            get { return _date }
            set { _date = newValue }
        }
        private var _repeats: Int16 = 0
        override var repeats: Int16 {
            get { return _repeats }
            set { _repeats = newValue }
        }
        private var _done: Bool = false
        override var done: Bool {
            get { return _done }
            set { _done = newValue }
        }
        private var _project: Project?
        override var project: Project? {
            get { return _project }
            set { _project = newValue }
        }
        private var _blocking: NSSet?
        override var blocking: NSSet? {
            get { return _blocking }
            set { _blocking = newValue }
        }
        private var _blockedBy: NSSet?
        override var blockedBy: NSSet? {
            get { return _blockedBy }
            set { _blockedBy = newValue }
        }
    }

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
