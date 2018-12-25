import UIKit

protocol BlockedCellViewStating {
    var titleText: String { get }
    var iconImage: UIImage? { get }
}

struct BlockedCellViewState: BlockedCellViewStating {
    let titleText: String
    let iconImage: UIImage?

    init(item: TodoItem, isBlocked: Bool = false) {
        titleText = item.name ?? ""
        iconImage = isBlocked ? Asset.Assets.tick.image : nil
    }
}
