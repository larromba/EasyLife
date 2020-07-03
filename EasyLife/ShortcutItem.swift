import UIKit

enum ShortcutItem: String, DisplayEnum {
    case newTodoItem = "NewTodoItem"

    static var display: [ShortcutItem] {
        return [.newTodoItem]
    }

    var item: UIApplicationShortcutItem {
        switch self {
        case .newTodoItem:
            return UIApplicationShortcutItem(
                type: rawValue,
                localizedTitle: L10n.shortcutItemNewTodoItemTitle,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .add),
                userInfo: nil
            )
        }
    }
}
