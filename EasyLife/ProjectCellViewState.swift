import UIKit

protocol ProjectCellViewStating {
    var titleText: String { get }
    var titleColor: UIColor { get }
}

struct ProjectCellViewState: ProjectCellViewStating {
    let titleText: String
    let titleColor: UIColor

    init(project: Project, section: ProjectSection) {
        titleText = project.name ?? ""
        //tagView.setup(for: item) // TODO: this

        switch section {
        case .other:
            titleColor = Asset.Colors.grey.color
        case .prioritized:
            titleColor = .black
        }
    }
}
