import UIKit

// sourcery: name = PlanCell
protocol PlanCellable: Mockable {
    var viewState: PlanCellViewStating? { get set }
    var delegate: PlanCellDelgate? { get set }
    var indexPath: IndexPath { get set }
}

protocol PlanCellDelgate: AnyObject {
    func cell(_ cell: PlanCellable, didLongPressAtIndexPath indexPath: IndexPath)
}

final class PlanCell: UITableViewCell, PlanCellable, CellIdentifiable, NibNameable {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var infoLabel: UILabel!
    @IBOutlet private(set) weak var notesLabel: UILabel!
    @IBOutlet private(set) weak var iconImageView: UIImageView!
    @IBOutlet private(set) weak var tagView: TagView!
    @IBOutlet private(set) weak var blockedView: BlockedIndicatorView!
    weak var delegate: PlanCellDelgate?
    var indexPath = IndexPath(row: 0, section: 0)

    var viewState: PlanCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(_:)))
        addGestureRecognizer(gestureRecognizer)
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

    @objc
    private func longPressAction(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began: delegate?.cell(self, didLongPressAtIndexPath: indexPath)
        default: break
        }
    }
}
