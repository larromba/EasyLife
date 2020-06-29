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
            let missingItems = try await(self.repository.fetchMissingFocusItems())
            guard missingItems.isEmpty else {
                onMain { self.showUnfocusableAlert() }
                return
            }
            let items = try await(self.repository.fetchTodayItems())
            guard !items.isEmpty else {
                onMain { self.delegate?.controllerFinished(self) }
                return
            }
            onMain { self.viewController?.viewState = FocusViewState(items: items) }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func showUnfocusableAlert() {
        let noAction = Alert.Action(title: L10n.unfocusableAlertNo, handler: {
            self.delegate?.controllerFinished(self)
        })
        let yesAction = Alert.Action(title: L10n.unfocusableAlertYes, handler: {
            self.moveMissingItems()
        })
        let alert = Alert(title: L10n.unfocusableAlertTitle,
                          message: L10n.unfocusableAlertMessage,
                          cancel: noAction,
                          actions: [yesAction],
                          textField: nil)
        alertController?.showAlert(alert)
    }

    private func moveMissingItems() {
        async({
            let missingItems = try await(self.repository.fetchMissingFocusItems())
            try missingItems.forEach { try await(self.repository.today(item: $0)) }
            self.reload()
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

    func viewController(_ viewController: FocusViewControlling, performAction action: FocusItemAction,
                        onItem item: TodoItem, at indexPath: IndexPath) {
        async({
            switch action {
            case .done: _ = try await(self.repository.done(item: item))
            }
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}
