import CoreGraphics
import Foundation

protocol BlockedByViewStating {
    var data: [BlockingContext<TodoItem>] { get }
    var sectionCount: Int { get }
    var rowCount: Int { get }
    var rowHeight: CGFloat { get }
    var isUnblockButtonEnabled: Bool { get }

    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewStating?

    func copy(data: [BlockingContext<TodoItem>]) -> BlockedByViewStating
}

struct BlockedByViewState: BlockedByViewStating {
    private(set) var data: [BlockingContext<TodoItem>]
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }
    let rowHeight: CGFloat = 50.0
    var isUnblockButtonEnabled: Bool {
        return !data.filter { $0.isBlocking }.isEmpty
    }

    init(item: TodoItem, items: [TodoItem]) {
        data = items.map { BlockingContext(object: $0, isBlocking: $0.blocking?.contains(item) ?? false) }
    }

    init(data: [BlockingContext<TodoItem>]) {
        self.data = data
    }

    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewStating? {
        let context = data[indexPath.row]
        return BlockedCellViewState(item: context.object, isBlocking: context.isBlocking)
    }
}

extension BlockedByViewState {
    func copy(data: [BlockingContext<TodoItem>]) -> BlockedByViewStating {
        return BlockedByViewState(data: data)
    }
}
