import UIKit

protocol FocusViewStating {
    var rowHeight: CGFloat { get }
    var isEditing: Bool { get }
    var totalItems: Int { get }
    var isEmpty: Bool { get }
    var numOfSections: Int { get }

    func title(for section: FocusSection) -> String?
    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> FocusCellViewStating?
    func items(for section: FocusSection) -> [TodoItem]?
    func name(at indexPath: IndexPath) -> String?
    func canMoveRow(at indexPath: IndexPath) -> Bool
    func availableActions(at indexPath: IndexPath) -> [ProjectItemAction]
    func color(for action: ProjectItemAction) -> UIColor
    func text(for action: ProjectItemAction) -> String
    func style(for action: ProjectItemAction) -> UITableViewRowAction.Style
}

struct FocusViewState: FocusViewStating {
    private let sections: [FocusSection: [TodoItem]]

    let rowHeight: CGFloat = 50.0
    let isEditing: Bool
    var totalItems: Int {
        return sections.reduce(0, { $0 + $1.value.count })
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    var numOfSections: Int {
        return sections.count
    }

    init(sections: [FocusSection: [TodoItem]], isEditing: Bool) {
        self.sections = sections
        self.isEditing = isEditing
    }

    func title(for section: FocusSection) -> String? {
        switch section {
        case .morning:
            return "TODO"
        case .afternoon:
            return "TODO"
        case .evening:
            return "TODO"
        case .unassigned:
            return "TODO"
        }
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        return nil
    }

    func cellViewState(at indexPath: IndexPath) -> FocusCellViewStating? {
        return nil
    }

    func items(for section: FocusSection) -> [TodoItem]? {
        return nil
    }

    func name(at indexPath: IndexPath) -> String? {
        return nil
    }

    func canMoveRow(at indexPath: IndexPath) -> Bool {
        return false
    }

    func availableActions(at indexPath: IndexPath) -> [ProjectItemAction] {
        return []
    }

    func color(for action: ProjectItemAction) -> UIColor {
        return .black
    }

    func text(for action: ProjectItemAction) -> String {
        return ""
    }

    func style(for action: ProjectItemAction) -> UITableViewRowAction.Style {
        return .default
    }
}
