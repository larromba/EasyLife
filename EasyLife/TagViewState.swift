import UIKit

protocol TagViewStating {
    var cornerColor: UIColor? { get }
    var labelText: String { get }
    var isHidden: Bool { get }
}

struct TagViewState: TagViewStating {
    let cornerColor: UIColor?
    let labelText: String
    let isHidden: Bool

    init(project: Project) {
        if project.priority == Project.defaultPriority {
            isHidden = true
            labelText = ""
            cornerColor = nil
        } else {
            isHidden = false
            labelText = "\(project.priority + 1)"

            switch project.priority {
            case 0: cornerColor = Asset.Colors.priority1.color
            case 1: cornerColor = Asset.Colors.priority2.color
            case 2: cornerColor = Asset.Colors.priority3.color
            case 3: cornerColor = Asset.Colors.priority4.color
            case 4: cornerColor = Asset.Colors.priority5.color
            default:
                assertionFailure("unhandled color priority")
                cornerColor = .clear
            }
        }
    }

    // MARK: - private

    private init() {
        isHidden = true
        labelText = ""
        cornerColor = nil
    }
}

extension TagViewState {
    static var none: TagViewState {
        return TagViewState()
    }
}
