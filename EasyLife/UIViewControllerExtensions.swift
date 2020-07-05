import UIKit

extension UIViewController {
    func hardReset() {
        if let presentedViewController = presentedViewController {
            presentedViewController.hardReset()
        }
        guard presentingViewController == nil else {
            dismiss(animated: false, completion: nil)
            return
        }
        if let self = self as? UINavigationController {
            self.popToRootViewController(animated: false)
        }
    }
}
