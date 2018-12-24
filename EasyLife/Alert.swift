import UIKit

struct Alert {
    struct Action {
        let title: String
        let handler: (() -> Void)?
    }
    final class TextField {
        let placeholder: String
        let text: String?
        let handler: (((String?) -> Void))?

        @objc
        private func textChanged(_ textField: UITextField) {
            handler?(textField.text)
        }

        init(placeholder: String, text: String?, handler: (((String?) -> Void))?) {
            self.placeholder = placeholder
            self.text = text
            self.handler = handler
        }
    }

    let title: String
    let message: String
    let cancel: Action
    let actions: [Action]
    let textField: TextField?
}

extension Alert {
    static func dataError(_ error: Error?) -> Alert {
        return Alert(title: "", message: "", cancel: Alert.Action(title: "", handler: nil), actions: [], textField: nil)
    }
}
