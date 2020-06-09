import UIKit

protocol FocusCellViewStating {
    var titleText: String { get }
    var titleColor: UIColor { get }
    var tagViewState: TagViewStating { get }
}

struct FocusCellViewState: FocusCellViewStating {
    let titleText: String
    let titleColor: UIColor
    let tagViewState: TagViewStating

    init(project: Project, section: FocusSection) {
        titleText = project.name ?? ""
        tagViewState = TagViewState(project: project)

        switch section {
        case .morning, .afternoon, .evening:
            titleColor = .black
        case .unassigned:
            titleColor = Asset.Colors.grey.color
        }
    }
}
