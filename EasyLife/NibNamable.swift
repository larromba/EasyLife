import Foundation

protocol NibNameable {
    static var nibName: String { get }
}

extension NibNameable {
    // defaults to class name if not implemented
    static var nibName: String {
        return "\(self)"
    }
}
