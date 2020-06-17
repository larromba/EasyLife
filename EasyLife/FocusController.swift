import AsyncAwait
import Foundation
import UIKit

// sourcery: name = FocusController
protocol FocusControlling: AnyObject, Mockable {
    func setViewController(_ viewController: FocusViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setDelegate(_ delegate: FocusControllerDelegate)
}

protocol FocusControllerDelegate: AnyObject {
    func controllerFinished(_ controller: FocusControlling)
}

final class FocusController: FocusControlling {
    private let repository: PlanRepositoring
    private weak var viewController: FocusViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: FocusControllerDelegate?

    init(repository: PlanRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: FocusViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
        reload()
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setDelegate(_ delegate: FocusControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func reload() {
        async({
            let items = try await(self.repository.fetchTodayItems())
            onMain {
                self.viewController?.viewState = FocusViewState(items: items)
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}

// MARK: - FocusViewControllerDelegate

extension FocusController: FocusViewControllerDelegate {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction) {
        switch action {
        case .close: delegate?.controllerFinished(self)
        }
    }

    func viewController(_ viewController: FocusViewControlling, performAction action: PlanItemAction,
                        onItem item: TodoItem, at indexPath: IndexPath) {
        async({
            switch action {
            case .done: _ = try await(self.repository.done(item: item))
            default: assertionFailure("unexpected switch state")
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}
