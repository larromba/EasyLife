import UIKit

protocol ProjectsViewStating {
    var rowHeight: CGFloat { get }
    var deleteTitle: String { get }
    var prioritizeTitle: String { get }
    var prioritizeColor: UIColor { get }
    var deprioritizeTitle: String { get }
    var deprioritizeColor: UIColor { get }
    var maxPriorityItems: Int { get }
    var isEditing: Bool { get }
    var totalItems: Int { get }
    var totalPriorityItems: Int { get }
    var totalNonPriorityItems: Int { get }
    var isMaxPriorityItemLimitReached: Bool { get }
    var isEmpty: Bool { get }
    var isEditable: Bool { get }
    var numOfSections: Int { get }

    func title(for section: ProjectSection) -> String?
    func project(at indexPath: IndexPath) -> Project?
    func cellViewState(at indexPath: IndexPath) -> ProjectCellViewStating?
    func items(for section: ProjectSection) -> [Project]?
    func name(at indexPath: IndexPath) -> String?
    func canMoveRow(at indexPath: IndexPath) -> Bool

    func copy(sections: [ProjectSection: [Project]]) -> ProjectsViewStating
}

struct ProjectsViewState: ProjectsViewStating {
    private let sections: [ProjectSection: [Project]]

    let rowHeight: CGFloat = 50.0
    let deleteTitle = L10n.todoItemOptionDelete
    let prioritizeTitle = L10n.projectOptionPrioritize
    let prioritizeColor = Asset.Colors.green.color
    let deprioritizeTitle = L10n.projectOptionDeprioritize
    let deprioritizeColor = Asset.Colors.grey.color
    let maxPriorityItems = 5
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
    var numOfSections: Int {
        return sections.count
    }

    init(sections: [ProjectSection: [Project]], isEditing: Bool) {
        self.sections = sections
        self.isEditing = isEditing
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

    func cellViewState(at indexPath: IndexPath) -> ProjectCellViewStating? {
        guard let section = ProjectSection(rawValue: indexPath.section) else { return nil }
        return project(at: indexPath).map { ProjectCellViewState(project: $0, section: section) }
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
    func copy(sections: [ProjectSection: [Project]]) -> ProjectsViewStating {
        return ProjectsViewState(sections: sections, isEditing: isEditing)
    }
}
