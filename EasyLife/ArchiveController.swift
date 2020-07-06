import AsyncAwait
import Foundation
import UIKit

// sourcery: name = ArchiveController
protocol ArchiveControlling: Mockable {
    func setDelegate(_ delegate: ArchiveControllerDelegate)
    func setViewController(_ viewController: ArchiveViewControlling)
}

protocol ArchiveControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ArchiveControlling)
    func controller(_ controller: ArchiveControlling, showAlert alert: Alert)
}

final class ArchiveController: ArchiveControlling {
    private let repository: ArchiveRepositoring
    private let dataProvider: ArchiveDataProviding
    private weak var delegate: ArchiveControllerDelegate?
    private weak var viewController: ArchiveViewControlling?

    init(repository: ArchiveRepositoring, dataProvider: ArchiveDataProviding = ArchiveDataProvider()) {
        self.repository = repository
        self.dataProvider = dataProvider
    }

    func setDelegate(_ delegate: ArchiveControllerDelegate) {
        self.delegate = delegate
    }

    func setViewController(_ viewController: ArchiveViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
        viewController.viewState = ArchiveViewState(sections: [:], text: nil, isSearching: false)
        reload()
    }

    // MARK: - private

    private func reload() {
        guard let viewState = viewController?.viewState else { return }
        async({
            let items = try await(self.repository.fetchItems())
            onMain {
                self.dataProvider.setupWithItems(items)
                self.viewController?.viewState = viewState.copy(sections: self.dataProvider.sections)
            }
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }

    private func showClearAllAlert() {
        let alert = Alert(
            title: L10n.archiveDeleteAllTitle,
            message: L10n.archiveDeleteAllMessage,
            cancel: Alert.Action(title: L10n.archiveDeleteAllOptionNo, handler: nil),
            actions: [Alert.Action(title: L10n.archiveDeleteAllOptionYes, handler: {
                self.clearAll()
            })],
            textField: nil)
        delegate?.controller(self, showAlert: alert)
    }

    private func clearAll() {
        guard let viewState = viewController?.viewState else { return }
        async({
            _ = try await(self.repository.clearAll(items: viewState.sections.flatMap { $0.value }))
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }

    private func undoItem(_ item: TodoItem) {
        async({
            _ = try await(self.repository.undo(item: item))
            self.reload()
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }
}

// MARK: - PlanViewControllerDelegate

extension ArchiveController: ArchiveViewControllerDelegate {
    func viewController(_ viewController: ArchiveViewControlling, performAction action: ArchiveAction) {
        switch action {
        case .clear:
            viewController.viewState = viewController.viewState?.copy(text: nil)
            viewController.endEditing()
            showClearAllAlert()
        case .done: delegate?.controllerFinished(self)
        case .undo(let item): undoItem(item)
        }
    }

    func viewControllerStartedSearch(_ viewController: ArchiveViewControlling) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: dataProvider.sections, isSearching: true)
    }

    func viewController(_ viewController: ArchiveViewControlling, performSearch term: String) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: dataProvider.sections(for: term))
    }

    func viewControllerEndedSearch(_ viewController: ArchiveViewControlling) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: dataProvider.sections, isSearching: false)
    }

    func viewControllerTapped(_ viewController: ArchiveViewControlling) {
        viewController.viewState = viewController.viewState?.copy(text: nil)
        viewController.endEditing()
    }
}
