import UIKit

// sourcery: name = FocusCell
protocol FocusCelling: Mockable {
    var viewState: FocusCellViewStating? { get set }
}

final class FocusCell: UITableViewCell, FocusCelling {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var tagView: TagView!

    var viewState: FocusCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: FocusCellViewStating) {
        titleLabel.text = viewState.titleText
        titleLabel.textColor = viewState.titleColor
        tagView.viewState = viewState.tagViewState
    }
}
