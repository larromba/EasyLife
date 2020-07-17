import UIKit

protocol ViewControllerCastable {
    var casted: UIViewController { get }
}
extension ViewControllerCastable {
    var casted: UIViewController {
        guard let self = self as? UIViewController else {
            assertionFailure("expected UIViewController")
            return UIViewController()
        }
        return self
    }
}
