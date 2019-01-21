import UIKit

// sourcery: name = PlanCell
protocol PlanCellable: Mockable {
    var viewState: PlanCellViewStating? { get set }
}

final class PlanCell: UITableViewCell, PlanCellable {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var infoLabel: UILabel!
    @IBOutlet private(set) weak var notesLabel: UILabel!
    @IBOutlet private(set) weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var tagView: TagView!
    @IBOutlet private(set) weak var blockedView: BlockedIndicatorView!

    var viewState: PlanCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: PlanCellViewStating) {
        blockedView.viewState = viewState.blockedIndicatorViewState
        iconImageView.image = viewState.iconImage
        iconImageView.isHidden = viewState.isIconHidden
        infoLabel.text = viewState.infoText
        tagView.viewState = viewState.tagViewState
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
