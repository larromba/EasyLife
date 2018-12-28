import Foundation
import CoreGraphics

protocol BlockedViewStating {
    var data: [BlockingContext<TodoItem>] { get }
    var sectionCount: Int { get }
    var rowCount: Int { get }
    var rowHeight: CGFloat { get }

    mutating func toggle(_ indexPath: IndexPath)
    func isBlocking(_ item: TodoItem) -> Bool
    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState?
}

struct BlockedViewState: BlockedViewStating {
    private(set) var data: [BlockingContext<TodoItem>]
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }
    let rowHeight: CGFloat = 50.0

    init(item: TodoItem, items: [TodoItem]) {
        data = items.map { BlockingContext(object: $0, isBlocking: $0.blocking?.contains(item) ?? false) }
    }

    mutating func toggle(_ indexPath: IndexPath) {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else { return }
        data[indexPath.row].isBlocking = !data[indexPath.row].isBlocking
    }

    func isBlocking(_ item: TodoItem) -> Bool {
        return data.first(where: { $0.object === item })?.isBlocking ?? false
    }

    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState? {
        let context = data[indexPath.row]
        return BlockedCellViewState(item: context.object, isBlocking: context.isBlocking)
    }
}
