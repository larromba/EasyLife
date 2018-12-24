import CoreGraphics
import Foundation

struct ProjectsViewState {
    let rowHeight: CGFloat = 50.0
    let deleteTitle = L10n.todoItemOptionDelete
    let prioritizeTitle = L10n.projectOptionPrioritize
    let prioritizeColor = Asset.Colors.green.color
    let deprioritizeTitle = L10n.projectOptionDeprioritize
    let deprioritizeColor = Asset.Colors.grey.color
    let maxPriorityItems = 5
    let sections: [ProjectSection: [Project]]
    let isEditing: Bool
    var totalItems: Int {
        return sections.reduce(0, { $0 + $1.value.count })
    }
    var totalPriorityItems: Int {
        return sections[.prioritized]?.count ?? 0
    }
    var totalNonPriorityItems: Int {
        return sections[.other]?.count ?? 0
    }
    var isMaxPriorityItemLimitReached: Bool {
        return totalPriorityItems >= maxPriorityItems
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    var isEditable: Bool {
        return !isEmpty
    }

    func title(for section: ProjectSection) -> String? {
        switch section {
        case .prioritized:
            return L10n.projectSectionPrioritized
        case .other:
            return L10n.projectSectionDeprioritized
        }
    }

    func project(at indexPath: IndexPath) -> Project? {
        guard
            let section = ProjectSection(rawValue: indexPath.section),
            let items = items(for: section),
            indexPath.row >= items.startIndex && indexPath.row < items.endIndex else {
                return nil
        }
        let row = items[indexPath.row]
        return row
    }

    func items(for section: ProjectSection) -> [Project]? {
        let section = sections[section]
        return section
    }

    func name(at indexPath: IndexPath) -> String? {
        guard let project = project(at: indexPath) else {
            return nil
        }
        return project.name
    }

    func canMoveRow(at indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ||
            (indexPath.section == 1 && !isMaxPriorityItemLimitReached && totalPriorityItems > 0)
    }
}

extension ProjectsViewState {
    func copy(sections: [ProjectSection: [Project]]) -> ProjectsViewState {
        return ProjectsViewState(sections: sections, isEditing: isEditing)
    }
}
