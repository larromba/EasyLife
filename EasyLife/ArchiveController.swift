import AsyncAwait
import Foundation
import UIKit

protocol ArchiveControlling {
    func setDelegate(_ delegate: ArchiveControllerDelegate)
    func setViewController(_ viewController: ArchiveViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

protocol ArchiveControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ArchiveController)
}

final class ArchiveController: ArchiveControlling {
    private let repository: ArchiveRepositoring
    private var viewController: ArchiveViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: ArchiveControllerDelegate?

    init(repository: ArchiveRepositoring) {
        self.repository = repository
    }

    func setDelegate(_ delegate: ArchiveControllerDelegate) {
        self.delegate = delegate
    }

    func setViewController(_ viewController: ArchiveViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
        viewController.viewState = ArchiveViewState(sections: [:], searchSections: [:], text: nil)
        reload()
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    // MARK: - private

    private func reload() {
        guard let viewState = viewController?.viewState else { return }
        async({
            let items = try await(self.repository.fetchItems())
            var sections = [Character: [TodoItem]]()
            items.forEach {
                let section: Character
                if let name = $0.name, !name.isEmpty {
                    section = Character(String(name[name.startIndex]).uppercased())
                } else {
                    section = Character("-")
                }
                var items = sections[section] ?? [TodoItem]()
                items.append($0)
                sections[section] = items.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
            }
            onMain {
                self.viewController?.viewState = viewState.copy(sections: sections, searchSections: nil)
            }
        }, onError: { error in
            self.alertController?.showAlert(.dataError(error))
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
        alertController?.showAlert(alert)
    }

    private func clearAll() {
        guard let viewState = viewController?.viewState else { return }
        async({
            _ = try await(self.repository.clearAll(items: viewState.sections.flatMap { $0.value }))
            onMain {
                self.viewController?.viewState = viewState.copy(sections: [:], searchSections: nil)
            }
        }, onError: { error in
            self.alertController?.showAlert(.dataError(error))
        })
    }

    private func undoItem(_ item: TodoItem) {
        async({
            _ = try await(self.repository.undo(item: item))
            self.reload()
        }, onError: { error in
            self.alertController?.showAlert(.dataError(error))
        })
    }
}

// MARK: - PlanViewControllerDelegate

extension ArchiveController: ArchiveViewControllerDelegate {
    func viewController(_ viewController: ArchiveViewController, performAction action: ArchiveAction) {
        switch action {
        case .clear: showClearAllAlert()
        case .done: delegate?.controllerFinished(self)
        case .undo(let item): undoItem(item)
        }
    }

    func viewControllerStartedSearch(_ viewController: ArchiveViewController) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(searchSections: viewState.sections)
    }

    func viewController(_ viewController: ArchiveViewController, performSearch term: String) {
        guard let viewState = viewController.viewState else { return }
        guard !term.isEmpty else {
            viewController.viewState = viewState.copy(searchSections: viewState.sections)
            return
        }
        var sections = viewState.sections
        for key in viewState.sections.keys {
            if let result = viewState.sections[key]?.filter({
                $0.name?.lowercased().contains(term.lowercased()) ?? false
            }), !result.isEmpty {
                sections[key] = result
            } else {
                sections.removeValue(forKey: key)
            }
        }
        viewController.viewState = viewState.copy(searchSections: sections)
    }

    func viewControllerEndedSearch(_ viewController: ArchiveViewController) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(searchSections: nil)
    }

    func viewControllerTapped(_ viewController: ArchiveViewController) {
        viewController.viewState = viewController.viewState?.copy(text: nil)
        viewController.endEditing()
    }
}
