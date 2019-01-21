import UIKit

protocol BlockedCellViewStating {
    var titleText: String { get }
    var iconImage: UIImage? { get }
}

struct BlockedCellViewState: BlockedCellViewStating {
    let titleText: String
    let iconImage: UIImage?

    init(item: TodoItem, isBlocking: Bool) {
        titleText = item.name ?? ""
        iconImage = isBlocking ? Asset.Assets.tick.image : nil
    }
}
