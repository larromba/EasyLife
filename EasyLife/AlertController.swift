import UIKit

protocol AlertControlling {
    func showAlert(_ alert: Alert)
}

final class AlertController: AlertControlling {
    private let presenter: Presentable

    init(presenter: Presentable) {
        self.presenter = presenter
    }

    func showAlert(_ alert: Alert) {
        let viewController = UIAlertController(title: alert.title,
                                               message: alert.message,
                                               preferredStyle: .alert)
        viewController.addAction(.init(title: alert.cancel.title, style: .cancel, handler: { _ in
            alert.cancel.handler?()
        }))
        alert.actions.forEach { action in
            viewController.addAction(.init(
                title: action.title,
                style: .default,
                handler: { _ in
                    action.handler?()
                })
            )
        }
        presenter.present(viewController, animated: true, completion: nil)
    }
}
