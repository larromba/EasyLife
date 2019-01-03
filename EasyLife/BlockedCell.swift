import UIKit

// sourcery: name = BlockedCell
protocol BlockedCelling: Mockable {
    var viewState: ProjectCellViewStating? { get set }
}

final class BlockedCell: UITableViewCell {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var iconImageView: UIImageView!

    var viewState: BlockedCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: BlockedCellViewStating) {
        titleLabel.text = viewState.titleText
        iconImageView.image = viewState.iconImage
    }
}
