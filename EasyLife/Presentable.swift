import UIKit

protocol Presentable: AnyObject {
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func present(_ viewControllerToPresent: ViewControllerCastable, animated flag: Bool, completion: (() -> Void)?)
}
extension UIViewController: Presentable {
    func present(_ viewControllerToPresent: ViewControllerCastable, animated flag: Bool, completion: (() -> Void)?) {
        present(viewControllerToPresent.casted, animated: flag, completion: completion)
    }
}
