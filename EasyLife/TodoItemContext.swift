import Foundation

enum TodoItemContext {
    case existing(item: TodoItem)
    case new(item: TodoItem, context: DataContexting)
}
