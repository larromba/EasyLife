import UIKit

protocol KeyboardNotificationDelegate: AnyObject {
    func keyboardWithShow(height: CGFloat)
    func keyboardWillHide()
}

final class KeyboardNotification {
    weak var delegate: KeyboardNotificationDelegate?

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }

    func tearDown() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    // MARK: - private

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let value = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        delegate?.keyboardWithShow(height: value.cgRectValue.height)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        delegate?.keyboardWillHide()
    }
}
