import Foundation

enum TodoItemContext {
    case new(item: TodoItem, context: DataContexting)
    case existing(item: TodoItem, context: DataContexting)
}
