import UIKit

// sourcery: name = ArchiveCell
protocol ArchiveCelling: Mockable {
    var viewState: ArchiveCellViewStating? { get set }
}

final class ArchiveCell: UITableViewCell, ArchiveCelling, CellIdentifiable {
    @IBOutlet private(set) weak var titleLabel: UILabel!

    var viewState: ArchiveCellViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: ArchiveCellViewStating) {
        titleLabel.text = viewState.titleText
        titleLabel.textColor = viewState.titleColor
    }
}
