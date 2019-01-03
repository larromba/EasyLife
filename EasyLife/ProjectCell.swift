import UIKit

// sourcery: name = ProjectCell
protocol ProjectCelling: Mockable {
    var viewState: ProjectCellViewStating? { get set }
}

final class ProjectCell: UITableViewCell, ProjectCelling {
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var tagView: TagView!

    var viewState: ProjectCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: ProjectCellViewStating) {
        titleLabel.text = viewState.titleText
        titleLabel.textColor = viewState.titleColor
        tagView.viewState = viewState.tagViewState
    }
}
