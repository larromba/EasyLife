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
