import UIKit

protocol ProjectCellViewStating {
    var titleText: String { get }
    var titleColor: UIColor { get }
    var tagViewState: TagViewStating { get }
}

struct ProjectCellViewState: ProjectCellViewStating {
    let titleText: String
    let titleColor: UIColor
    let tagViewState: TagViewStating

    init(project: Project, section: ProjectSection) {
        titleText = project.name ?? ""
        tagViewState = TagViewState(project: project)

        switch section {
        case .other:
            titleColor = Asset.Colors.grey.color
        case .prioritized:
            titleColor = .black
        }
    }
}
