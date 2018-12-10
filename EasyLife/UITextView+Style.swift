import UIKit

extension UITextView {
    func applyTextFieldStyle() {
        layer.cornerRadius = 5.0
        layer.borderColor = UIColor.appleGrey.cgColor
        layer.borderWidth = 0.5
        textContainerInset.left = 2.0
        textContainerInset.right = 2.0
    }
}
