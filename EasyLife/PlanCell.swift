import UIKit

protocol PlanCellable {
    var viewState: PlanCellViewStating? { get set }
}

final class PlanCell: UITableViewCell, PlanCellable {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var infoLabel: UILabel!
    @IBOutlet private(set) weak var notesLabel: UILabel!
    @IBOutlet private(set) weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var tagView: TagView!
    @IBOutlet private(set) weak var blockedView: BlockedBackgroundView!

    var viewState: PlanCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: PlanCellViewStating) {
        blockedView.viewState = viewState.blockedBackgroundViewState
        iconImageView.image = viewState.iconImage
        iconImageView.isHidden = viewState.isIconHidden
        infoLabel.text = viewState.infoText
        // tagView.setup(for: item.project) // TODO: this
        titleLabel.text = viewState.titleText
        titleLabel.textColor = viewState.titleColor
        notesLabel.isHidden = viewState.isNotesLabelHidden
        infoLabel.text = viewState.infoText
        infoLabel.textColor = viewState.infoColor
        notesLabel.text = viewState.notesText
        notesLabel.textColor = viewState.notesColor
        tagView.alpha = viewState.tagViewAlpha
        infoLabel.isHidden = viewState.isInfoLabelHidden
    }
}
