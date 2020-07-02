import Foundation

protocol PickerItem {
    associatedtype Object

    var title: String? { get }
    var object: Object { get }
}
