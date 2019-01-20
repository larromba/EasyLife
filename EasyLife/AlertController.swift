import UIKit

// sourcery: name = AlertController
protocol AlertControlling: Mockable {
    func showAlert(_ alert: Alert)
    func setIsButtonEnabled(_ isEnabled: Bool, at index: Int)
}

final class AlertController: AlertControlling {
    private weak var presenter: Presentable?
    private weak var currentAlert: UIAlertController?
    private let alertActionFactory: AlertActionFactoring

    init(presenter: Presentable, alertActionFactory: AlertActionFactoring = AlertActionFactory()) {
        self.presenter = presenter
        self.alertActionFactory = alertActionFactory
    }

    func showAlert(_ alert: Alert) {
        guard currentAlert == nil else { return }
        let viewController = UIAlertController(title: alert.title,
                                               message: alert.message,
                                               preferredStyle: .alert)
        viewController.addAction(alertActionFactory.make(withTitle: alert.cancel.title, style: .cancel, handler: { _ in
            alert.cancel.handler?()
        }))
        alert.actions.forEach { action in
            viewController.addAction(alertActionFactory.make(
                withTitle: action.title,
                style: .default,
                handler: { _ in
                    action.handler?()
                })
            )
        }
        if let alertTextField = alert.textField {
            viewController.addTextField { textField in
                textField.text = alertTextField.text
                textField.placeholder = alertTextField.placeholder
                textField.addTarget(alertTextField, action: #selector(alertTextField.textChanged(_:)),
                                    for: .editingChanged)
            }
        }
        presenter?.present(viewController, animated: true, completion: nil)
        currentAlert = viewController
    }

    func setIsButtonEnabled(_ isEnabled: Bool, at index: Int) {
        guard let currentAlert = currentAlert else { return }
        currentAlert.actions[index].isEnabled = isEnabled
    }
}
