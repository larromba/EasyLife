import UIKit

protocol ArchiveCellViewStating {
    var titleText: String { get }
    var titleColor: UIColor { get }
}

struct ArchiveCellViewState: ArchiveCellViewStating {
    let titleText: String
    let titleColor: UIColor

    init(item: TodoItem) {
        if let name = item.name, !name.isEmpty {
            titleText = name
            titleColor = .black
        } else {
            titleText = L10n.todoItemNoName
            titleColor = Asset.Colors.grey.color
        }
    }
}
