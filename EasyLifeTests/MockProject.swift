import Foundation
@testable import EasyLife

class MockProject: Project {
    private var _name: String?
    override var name: String? {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    private var _priority: Int16 = Project.defaultPriority
    override var priority: Int16 {
        get {
            return _priority
        }
        set {
            _priority = newValue
        }
    }
}
