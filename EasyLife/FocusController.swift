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
    private let repository: FocusRepositoring
    private weak var viewController: FocusViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: FocusControllerDelegate?

    init(repository: FocusRepositoring) {
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
            // focuses items in the today section only
            // these items must not be blocked by items in other sections
            // if so, show an alert
            let missingItems = try await(self.repository.fetchMissingItems())
            guard missingItems.isEmpty else {
                onMain { self.showUnfocusableAlert() }
                return
            }
            // ensure first item can be done, else it's recursively blocked.
            // blocking items are prioritized, so nothing can be done if:
            // a blocks b
            // b blocks c
            // c blocks a
            guard try await(self.repository.isDoable()) else {
                onMain { self.showRecursivelyBlockedAlert() }
                return
            }
            // items are presented one at a time, so if no more items, finish
            let items = try await(self.repository.fetchItems())
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
        let cancelAction = Alert.Action(title: L10n.unfocusableAlertNo, handler: {
            self.delegate?.controllerFinished(self)
        })
        let confirmAction = Alert.Action(title: L10n.unfocusableAlertYes, handler: {
            self.moveMissingItems()
        })
        let alert = Alert(title: L10n.unfocusableAlertTitle,
                          message: L10n.unfocusableAlertMessage,
                          cancel: cancelAction,
                          actions: [confirmAction],
                          textField: nil)
        alertController?.showAlert(alert)
    }

    private func showRecursivelyBlockedAlert() {
        let cancelAction = Alert.Action(title: L10n.recursivelyBlockedAlertOk, handler: {
            self.delegate?.controllerFinished(self)
        })
        let alert = Alert(title: L10n.recursivelyBlockedAlertTitle,
                          message: L10n.recursivelyBlockedAlertMessage,
                          cancel: cancelAction,
                          actions: [],
                          textField: nil)
        alertController?.showAlert(alert)
    }

    private func moveMissingItems() {
        async({
            let missingItems = try await(self.repository.fetchMissingItems())
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
