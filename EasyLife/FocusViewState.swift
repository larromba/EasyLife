import UIKit

protocol FocusViewUIUpdatable {
    var date: Date? { get set }
    var focusTime: FocusTime { get set }
}

protocol FocusViewStating: FocusViewUIUpdatable {
    var item: TodoItem? { get }
    var rowHeight: CGFloat { get }
    var totalItems: Int { get }
    var isEmpty: Bool { get }
    var numOfSections: Int { get }
    var numOfPickerRows: Int { get }
    var numOfPickerComponents: Int { get }
    var backgroundColor: UIColor { get }
    var tableFadeAnimationDuation: TimeInterval { get }
    var timerButtonViewState: TimerButtonViewStating { get }

    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating?
    func availableActions(at indexPath: IndexPath) -> [FocusItemAction]
    func color(for action: FocusItemAction) -> UIColor
    func text(for action: FocusItemAction) -> String
    func style(for action: FocusItemAction) -> UITableViewRowAction.Style
    func pickerItem(at row: Int) -> FocusPickerItem

    func copy(backgroundColor: UIColor, timerButtonViewState: TimerButtonViewStating) -> FocusViewStating
    func copy(backgroundColor: UIColor) -> FocusViewStating
    func copy(timerButtonViewState: TimerButtonViewStating) -> FocusViewStating
}

struct FocusViewState: FocusViewStating {
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
    let numOfSections: Int = 1
    let numOfPickerComponents: Int = 1
    var numOfPickerRows: Int {
        return pickerItems.count
    }
    let backgroundColor: UIColor
    let tableFadeAnimationDuation: TimeInterval = 0.5
    let timerButtonViewState: TimerButtonViewStating

    var date: Date?
    var focusTime: FocusTime

    private let items: [TodoItem]
    private let pickerItems: [FocusPickerItem] = FocusTime.display.map { FocusPickerItem(object: $0) }

    init(items: [TodoItem], backgroundColor: UIColor, timerButtonViewState: TimerButtonViewStating,
         focusTime: FocusTime) {
        self.items = items
        self.backgroundColor = backgroundColor
        self.timerButtonViewState = timerButtonViewState
        self.focusTime = focusTime
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        return items[indexPath.row]
    }

    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating? {
        return item(at: indexPath).map { PlanCellViewState(item: $0, section: .today) }
    }

    func availableActions(at indexPath: IndexPath) -> [FocusItemAction] {
        guard let item = item, (item.blockedBy?.count ?? 0) == 0 else { return [] }
        return [.done]
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

    func pickerItem(at row: Int) -> FocusPickerItem {
        return pickerItems[row]
    }
}

extension FocusViewState {
    func copy(backgroundColor: UIColor, timerButtonViewState: TimerButtonViewStating) -> FocusViewStating {
        return FocusViewState(items: items, backgroundColor: backgroundColor,
                              timerButtonViewState: timerButtonViewState, focusTime: focusTime)
    }

    func copy(timerButtonViewState: TimerButtonViewStating) -> FocusViewStating {
        return FocusViewState(items: items, backgroundColor: backgroundColor,
                              timerButtonViewState: timerButtonViewState, focusTime: focusTime)
    }

    func copy(backgroundColor: UIColor) -> FocusViewStating {
        return FocusViewState(items: items, backgroundColor: backgroundColor,
                              timerButtonViewState: timerButtonViewState, focusTime: focusTime)
    }
}
