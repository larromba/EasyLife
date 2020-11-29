import UIKit

protocol KeyboardNotificationDelegate: AnyObject {
    func keyboardWithShow(height: CGFloat)
    func keyboardWillHide()
}

final class KeyboardNotification {
    weak var delegate: KeyboardNotificationDelegate?
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    func setup() {
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                       name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                       name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func tearDown() {
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    // MARK: - private

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        delegate?.keyboardWithShow(height: value.cgRectValue.height)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        delegate?.keyboardWillHide()
    }
}
