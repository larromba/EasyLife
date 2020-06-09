import UIKit

protocol FocusViewStating {
    var rowHeight: CGFloat { get }
    var totalItems: Int { get }
    var isEmpty: Bool { get }
    var numOfSections: Int { get }
    var backgroundColor: UIColor { get }

    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating?
    func name(at indexPath: IndexPath) -> String?
    func availableActions(at indexPath: IndexPath) -> [PlanItemAction]
    func color(for action: PlanItemAction) -> UIColor
    func text(for action: PlanItemAction) -> String
    func style(for action: PlanItemAction) -> UITableViewRowAction.Style
}

struct FocusViewState: FocusViewStating {
    private let items: [TodoItem]

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

    func availableActions(at indexPath: IndexPath) -> [PlanItemAction] {
        guard let item = items.first else { return [] }
        var actions = [PlanItemAction]()
        if (item.blockedBy?.count ?? 0) == 0 {
            actions += [.done]
        }
        return actions
    }

    func color(for action: PlanItemAction) -> UIColor {
        switch action {
        case .delete: return Asset.Colors.red.color
        case .done: return Asset.Colors.green.color
        case .later: return Asset.Colors.grey.color
        case .split: return Asset.Colors.grey.color
        }
    }

    func text(for action: PlanItemAction) -> String {
        switch action {
        case .delete: return  L10n.todoItemOptionDelete
        case .done: return L10n.todoItemOptionDone
        case .later: return L10n.todoItemOptionLater
        case .split: return L10n.todoItemOptionSplit
        }
    }

    func style(for action: PlanItemAction) -> UITableViewRowAction.Style {
        switch action {
        case .delete: return  .destructive
        case .done: return .normal
        case .later: return .normal
        case .split: return .normal
        }
    }
}
