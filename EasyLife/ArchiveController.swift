import AsyncAwait
import Foundation
import UIKit

// sourcery: name = ArchiveController
protocol ArchiveControlling: Mockable {
    func setDelegate(_ delegate: ArchiveControllerDelegate)
    func setViewController(_ viewController: ArchiveViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

protocol ArchiveControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ArchiveController)
}

final class ArchiveController: ArchiveControlling {
    private let repository: ArchiveRepositoring
    private weak var viewController: ArchiveViewControlling?
    private var alertController: AlertControlling?
    private weak var delegate: ArchiveControllerDelegate?
    private var sections = [Character: [TodoItem]]()

    init(repository: ArchiveRepositoring) {
        self.repository = repository
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

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    // MARK: - private

    private func reload() {
        guard let viewState = viewController?.viewState else { return }
        async({
            let items = try await(self.repository.fetchItems())
            onMain {
                self.sections = self.sections(for: items)
                self.viewController?.viewState = viewState.copy(sections: self.sections)
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
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
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func undoItem(_ item: TodoItem) {
        async({
            _ = try await(self.repository.undo(item: item))
            self.reload()
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func sections(for items: [TodoItem]) -> [Character: [TodoItem]] {
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
        return sections
    }

    private func sections(for term: String) -> [Character: [TodoItem]] {
        guard !term.isEmpty else {
            return sections
        }
        var filteredSections = [Character: [TodoItem]]()
        sections.keys.forEach {
            if let result = sections[$0]?.filter({
                $0.name?.lowercased().range(of: term, options: .caseInsensitive) != nil
            }), !result.isEmpty {
                filteredSections[$0] = result
            } else {
                filteredSections.removeValue(forKey: $0)
            }
        }
        return filteredSections
    }
}

// MARK: - PlanViewControllerDelegate

extension ArchiveController: ArchiveViewControllerDelegate {
    func viewController(_ viewController: ArchiveViewController, performAction action: ArchiveAction) {
        switch action {
        case .clear:
            viewController.viewState = viewController.viewState?.copy(text: nil)
            viewController.endEditing()
            showClearAllAlert()
        case .done: delegate?.controllerFinished(self)
        case .undo(let item): undoItem(item)
        }
    }

    func viewControllerStartedSearch(_ viewController: ArchiveViewController) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: sections, isSearching: true)
    }

    func viewController(_ viewController: ArchiveViewController, performSearch term: String) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: sections(for: term))
    }

    func viewControllerEndedSearch(_ viewController: ArchiveViewController) {
        guard let viewState = viewController.viewState else { return }
        viewController.viewState = viewState.copy(sections: sections, isSearching: false)
    }

    func viewControllerTapped(_ viewController: ArchiveViewController) {
        viewController.viewState = viewController.viewState?.copy(text: nil)
        viewController.endEditing()
    }
}
