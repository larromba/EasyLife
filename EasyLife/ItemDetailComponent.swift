import Foundation

enum ItemDetailComponent: Int {
    case repeatState
    case projects
}

protocol ComponentItem {
    associatedtype Object

    var title: String? { get }
    var object: Object { get }
}

struct ProjectComponentItem: ComponentItem {
    var title: String? {
        return object.name
    }
    let object: Project
}

struct RepeatStateComponentItem: ComponentItem {
    var title: String? {
        return object.stringValue()
    }
    let object: RepeatState
}

class AnyComponentItem<T>: ComponentItem {
    private let _title: String?
    private let _object: T

    var title: String? {
        return _title
    }

    var object: T {
        return _object
    }

    init<U: ComponentItem>(_ item: U) where U.Object == T {
        _title = item.title
        _object = item.object
    }
}
