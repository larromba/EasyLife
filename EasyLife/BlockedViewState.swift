import CoreGraphics
import Foundation

protocol BlockedByViewStating {
    var data: [BlockingContext<TodoItem>] { get }
    var sectionCount: Int { get }
    var rowCount: Int { get }
    var rowHeight: CGFloat { get }

    //func isBlocking(_ item: TodoItem) -> Bool
    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState?

    func copy(data: [BlockingContext<TodoItem>]) -> BlockedByViewState
}

struct BlockedByViewState: BlockedByViewStating {
    private(set) var data: [BlockingContext<TodoItem>]
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }
    let rowHeight: CGFloat = 50.0

    init(item: TodoItem, items: [TodoItem]) {
        data = items.map { BlockingContext(object: $0, isBlocking: $0.blocking?.contains(item) ?? false) }
    }

    init(data: [BlockingContext<TodoItem>]) {
        self.data = data
    }

//    func isBlocking(_ item: TodoItem) -> Bool {
//        return data.first(where: { $0.object === item })?.isBlocking ?? false
//    }

    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState? {
        let context = data[indexPath.row]
        return BlockedCellViewState(item: context.object, isBlocking: context.isBlocking)
    }
}

extension BlockedByViewState {
    func copy(data: [BlockingContext<TodoItem>]) -> BlockedByViewState {
        return BlockedByViewState(data: data)
    }
}
