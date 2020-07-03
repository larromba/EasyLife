import UIKit

extension UIViewController {
    var asAlertController: UIAlertController? {
        return self as? UIAlertController
    }

    func prepareView() {
        _ = view
    }
}
