import Foundation

enum ArchiveAction {
    case done
    case clear
    case undo(TodoItem)
}
