import Foundation
import CoreGraphics

struct BlockedViewState {
    var data: [BlockedItem]!
    var item: TodoItem?
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }
    var rowHeight: CGFloat = 50.0

    mutating func toggle(_ indexPath: IndexPath) {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else {
            return
        }
        data[indexPath.row].isBlocked = !data[indexPath.row].isBlocked
    }

    func isBlocked(_ item: TodoItem) -> Bool {
        return data.first(where: { $0.item === item })?.isBlocked ?? false
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else {
            return nil
        }
        return self.data[indexPath.row].item
    }
}
