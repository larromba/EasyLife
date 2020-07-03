import Foundation

enum PlanItemLongPressAction {
    case doToday
    case doTomorrow
    case moveAllToday(items: [TodoItem])
    case moveAllTomorrow(items: [TodoItem])

    var title: String {
        switch self {
        case .doToday: return L10n.planItemLongPressActionShortcutToday
        case .doTomorrow: return  L10n.planItemLongPressActionShortcutTomorrow
        case .moveAllToday: return  L10n.planItemLongPressActionShortcutAllToday
        case .moveAllTomorrow: return  L10n.planItemLongPressActionShortcutAllTomorrow
        }
    }
}
