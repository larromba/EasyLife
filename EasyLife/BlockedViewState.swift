import Foundation
import CoreGraphics

protocol BlockedViewStating {
    var item: TodoItem? { get }
    var sectionCount: Int { get }
    var rowCount: Int { get }
    var rowHeight: CGFloat { get }

    mutating func toggle(_ indexPath: IndexPath)
    func isBlocked(_ item: TodoItem) -> Bool
    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState?
}

struct BlockedViewState: BlockedViewStating {
    private var data: [BlockedItem]

    var item: TodoItem? // TODO: ?
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }
    let rowHeight: CGFloat = 50.0

    init(items: [TodoItem]) {
        data = items.map { BlockedItem(item: $0, isBlocked: false) }
    }

    mutating func toggle(_ indexPath: IndexPath) {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else { return }
        data[indexPath.row].isBlocked = !data[indexPath.row].isBlocked
    }

    func isBlocked(_ item: TodoItem) -> Bool {
        return data.first(where: { $0.item === item })?.isBlocked ?? false
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else { return nil }
        return data[indexPath.row].item
    }

    func cellViewState(at indexPath: IndexPath) -> BlockedCellViewState? {
        return item(at: indexPath).map { return BlockedCellViewState(item: $0) }
    }
}
