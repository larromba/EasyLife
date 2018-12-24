import CoreData
import CoreGraphics
import Foundation

// TODO: this?
//    #if DEBUG
//    //dataSource.itunesConnect()
//    #endif
//         self.viewController = UIStoryboard.plan.instantiateInitialViewController() as! PlanViewController

struct PlanViewState {
    let sections: [PlanSection: [TodoItem]]
    let rowHeight: CGFloat = 50.0
    let tableHeaderReletiveHeight: CGFloat = 0.3
    let isTableHeaderAnimating: Bool
    let deleteBackgroundColor = Asset.Colors.red.color
    let doneBackgroundColor = Asset.Colors.green.color
    let splitBackgroundColor = Asset.Colors.grey.color
    let laterBackgroundColor = Asset.Colors.grey.color

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

    func title(for section: PlanSection) -> String? {
        guard let items = sections[section], !items.isEmpty else {
            return nil
        }
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
        guard let section = PlanSection(rawValue: indexPath.section), let items = items(for: section) else {
            return nil
        }
        return items[indexPath.row]
    }

    func items(for section: PlanSection) -> [TodoItem]? {
        return sections[section]
    }

    func availableActions(for item: TodoItem, in section: PlanSection) -> [PlanItemAction] {
        var actions = [PlanItemAction]()
        if (item.blockedBy?.count ?? 0) == 0 {
            actions += [.done]
        }
        actions += [.delete]

        switch section {
        case .missed:
            if item.repeatState != RepeatState.none {
                actions += [.split]
            }
        case .today:
            if item.repeatState == RepeatState.none {
                actions += [.later]
            } else {
                actions += [.later, .split]
            }
        case .later:
            break
        }

        return actions
    }
}

extension PlanViewState {
    func copy(sections: [PlanSection: [TodoItem]]) -> PlanViewState {
        return PlanViewState(sections: sections, isTableHeaderAnimating: isTableHeaderAnimating)
    }

    func copy(isTableHeaderAnimating: Bool) -> PlanViewState {
        return PlanViewState(sections: sections, isTableHeaderAnimating: isTableHeaderAnimating)
    }
}
