import CoreData
import CoreGraphics
import UIKit

protocol PlanViewStating {
    var rowHeight: CGFloat { get }
    var fadeInDuration: TimeInterval { get }
    var fadeOutDuration: TimeInterval { get }
    var appVersionText: String { get }
    var tableHeaderHeightPercentage: CGFloat { get }
    var total: Int { get }
    var totalMissed: Int { get }
    var totalToday: Int { get }
    var totalLater: Int { get }
    var isDoneTotally: Bool { get }
    var isDoneForNow: Bool { get }
    var isDoneHidden: Bool { get }
    var isTableHeaderHidden: Bool { get }
    var isTableHidden: Bool { get }
    var isFocusButtonEnabled: Bool { get }
    var numOfSections: Int { get }
    var tableReloadAnimationDuration: TimeInterval { get }

    func color(for action: PlanItemAction) -> UIColor
    func text(for action: PlanItemAction) -> String
    func style(for action: PlanItemAction) -> UITableViewRowAction.Style
    func title(for section: Int) -> String?
    func item(at indexPath: IndexPath) -> TodoItem?
    func items(for section: Int) -> [TodoItem]?
    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating?
    func availableActions(for item: TodoItem, at indexPath: IndexPath) -> [PlanItemAction]
    func availableLongPressActions(at indexPath: IndexPath) -> [PlanItemLongPressAction]
    func tableHeaderAlpha(forHeight height: CGFloat, scrollOffsetY: CGFloat) -> CGFloat

    func copy(sections: [PlanSection: [TodoItem]], isDoneHidden: Bool) -> PlanViewStating
}

struct PlanViewState: PlanViewStating {
    private(set) var sections: [PlanSection: [TodoItem]]

    let rowHeight: CGFloat = 50.0
    let fadeInDuration = 0.2
    let fadeOutDuration = 0.4
    let appVersionText = Bundle.appVersion()
    var tableHeaderHeightPercentage: CGFloat {
        return isTableHeaderHidden ? 0.0 : 0.3
    }
    var total: Int {
        return sections.reduce(0) { $0 + $1.value.count }
    }
    var totalMissed: Int {
        return sections[.missed]?.count ?? 0
    }
    var totalToday: Int {
        return sections[.today]?.count ?? 0
    }
    var totalLater: Int {
        return sections[.later]?.count ?? 0
    }
    var isDoneTotally: Bool {
        return total == 0
    }
    var isDoneForNow: Bool {
        return totalMissed == 0 && totalToday == 0
    }
    let isDoneHidden: Bool
    var isTableHeaderHidden: Bool {
        return !isDoneForNow || isTableHidden
    }
    var isTableHidden: Bool {
        return isDoneTotally
    }
    var isFocusButtonEnabled: Bool {
        return totalToday == 0 ? false : true
    }
    var numOfSections: Int {
        return sections.count
    }
    let tableReloadAnimationDuration: TimeInterval = 0.3

    init(sections: [PlanSection: [TodoItem]], isDoneHidden: Bool) {
        self.sections = sections
        self.isDoneHidden = isDoneHidden
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

    func title(for section: Int) -> String? {
        guard
            let section = PlanSection(rawValue: section),
            let items = sections[section], !items.isEmpty else { return nil }
        switch section {
        case .missed:
            return L10n.missedSection
        case .today:
            return L10n.todaySection
        case .later:
            return L10n.laterSection
        }
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        return items(for: indexPath.section)?[indexPath.row]
    }

    func items(for section: Int) -> [TodoItem]? {
        guard let section = PlanSection(rawValue: section) else { return nil }
        return sections[section]
    }

    func cellViewState(at indexPath: IndexPath) -> PlanCellViewStating? {
        guard let section = PlanSection(rawValue: indexPath.section) else { return nil }
        return item(at: indexPath).map { PlanCellViewState(item: $0, section: section) }
    }

    func availableActions(for item: TodoItem, at indexPath: IndexPath) -> [PlanItemAction] {
        guard let section = PlanSection(rawValue: indexPath.section) else { return [] }

        var actions = [PlanItemAction]()
        if (item.blockedBy?.count ?? 0) == 0 {
            actions += [.done]
        }
        actions += [.delete]

        switch section {
        case .missed:
            if item.repeatState != .default {
                actions += [.split]
            }
        case .today:
            if item.repeatState == .default {
                actions += [.later]
            } else {
                actions += [.later, .split]
            }
        case .later:
            break
        }

        return actions
    }

    func availableLongPressActions(at indexPath: IndexPath) -> [PlanItemLongPressAction] {
        guard let section = PlanSection(rawValue: indexPath.section),
            let items = self.items(for: section.rawValue) else { return [] }
        switch section {
        case .missed:
            if items.count > 1 {
                return [.doToday, .doTomorrow, .moveAllToday(items: items), .moveAllTomorrow(items: items)]
            } else {
                return [.doToday, .doTomorrow]
            }
        case .today, .later:
            return []
        }
    }

    func tableHeaderAlpha(forHeight height: CGFloat, scrollOffsetY: CGFloat) -> CGFloat {
        guard scrollOffsetY < 0.0, height > 0.0 else { return 1.0 }
        return max(0.0, 1.0 - (abs(scrollOffsetY) / (height / 4.0)))
    }
}

extension PlanViewState {
    func copy(sections: [PlanSection: [TodoItem]], isDoneHidden: Bool) -> PlanViewStating {
        return PlanViewState(sections: sections, isDoneHidden: isDoneHidden)
    }
}
