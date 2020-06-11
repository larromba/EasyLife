import Foundation

enum PlanItemContext {
    case existing(item: TodoItem)
    case new(item: TodoItem, context: DataContexting)
}
