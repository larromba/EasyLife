import UIKit

protocol FocusViewStating {
    var item: TodoItem? { get }
    var rowHeight: CGFloat { get }
    var totalItems: Int { get }
    var isEmpty: Bool { get }
    var numOfSections: Int { get }
    var backgroundColor: UIColor { get }
    var tableFadeAnimationDuation: TimeInterval { get }

    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating?
    func name(at indexPath: IndexPath) -> String?
    func availableActions(at indexPath: IndexPath) -> [FocusItemAction]
    func color(for action: FocusItemAction) -> UIColor
    func text(for action: FocusItemAction) -> String
    func style(for action: FocusItemAction) -> UITableViewRowAction.Style
}

struct FocusViewState: FocusViewStating {
    private let items: [TodoItem]

    var item: TodoItem? {
        return items.first
    }
    let rowHeight: CGFloat = 50.0
    var totalItems: Int {
        return items.isEmpty ? 0 : 1
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    var numOfSections: Int {
        return 1
    }
    var backgroundColor: UIColor {
        return .black
    }
    var tableFadeAnimationDuation: TimeInterval = 0.5

    init(items: [TodoItem]) {
        self.items = items
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        return items[indexPath.row]
    }

    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating? {
        return item(at: indexPath).map { PlanCellViewState(item: $0, section: .today) }
    }

    func name(at indexPath: IndexPath) -> String? {
        return nil
    }

    func availableActions(at indexPath: IndexPath) -> [FocusItemAction] {
        guard let item = items.first else { return [] }
        var actions = [FocusItemAction]()
        if (item.blockedBy?.count ?? 0) == 0 {
            actions += [.done]
        }
        return actions
    }

    func color(for action: FocusItemAction) -> UIColor {
        switch action {
        case .done: return Asset.Colors.green.color
        }
    }

    func text(for action: FocusItemAction) -> String {
        switch action {
        case .done: return L10n.todoItemOptionDone
        }
    }

    func style(for action: FocusItemAction) -> UITableViewRowAction.Style {
        switch action {
        case .done: return .normal
        }
    }
}
