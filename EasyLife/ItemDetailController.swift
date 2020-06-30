import AsyncAwait
import Foundation

// sourcery: name = ItemDetailController
protocol ItemDetailControlling: TodoItemContexting, Mockable {
    func setViewController(_ viewController: ItemDetailViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setDelegate(_ delegate: ItemDetailControllerDelegate)
}

protocol ItemDetailControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ItemDetailControlling)
}

final class ItemDetailController: ItemDetailControlling {
    private weak var viewController: ItemDetailViewControlling?
    private let repository: ItemDetailRepositoring
    private var alertController: AlertControlling?
    private var context: EditContext<TodoItem>?
    private weak var delegate: ItemDetailControllerDelegate?

    init(repository: ItemDetailRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: ItemDetailViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setDelegate(_ delegate: ItemDetailControllerDelegate) {
        self.delegate = delegate
    }

    func setContext(_ context: TodoItemContext) {
        switch context {
        case let .new(item, dataContext):
            self.context = EditContext(value: item)
            viewController?.viewState = ItemDetailViewState(item: item, isNew: true, items: [], projects: [])
            repository.setContext(dataContext)
        case let .existing(item, dataContext):
            self.context = EditContext(value: item)
            viewController?.viewState = ItemDetailViewState(item: item, isNew: false, items: [], projects: [])
            repository.setContext(dataContext)
        }
        reload()
    }

    // MARK: - private

    private func showCancelAlert() {
        let alert = Alert(
            title: L10n.unsavedChangesTitle,
            message: L10n.unsavedChangesMessage,
            cancel: Alert.Action(title: L10n.unsavedChangesNo, handler: {
                self.dontSave()
            }),
            actions: [Alert.Action(title: L10n.unsavedChangesYes, handler: {
                self.save()
            })],
            textField: nil
        )
        alertController?.showAlert(alert)
    }

    private func reload() {
        guard let item = context?.value else { return }
        async({
            let items = try await(self.repository.fetchItems(for: item))
            let projects = try await(self.repository.fetchProjects(for: item))
            onMain {
                let viewState = self.viewController?.viewState?.copy(item: item, items: items, projects: projects)
                self.viewController?.viewState = viewState
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func cancel() {
        if hasUnsavedChanges() {
            showCancelAlert()
        } else {
            dontSave()
        }
    }

    private func hasUnsavedChanges() -> Bool {
        if let item = context?.value, !item.isEmpty {
            return true
        } else {
            return false
        }
    }

    private func dontSave() {
        context = nil
        delegate?.controllerFinished(self)
    }

    private func save() {
        guard let item = context?.value else { return }
        async({
            _ = try await(self.repository.save(item: item))
            onMain { self.delegate?.controllerFinished(self) }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private func delete() {
        guard let item = context?.value else { return }
        async({
            _ = try await(self.repository.delete(item: item))
            onMain { self.delegate?.controllerFinished(self) }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private  func updateItem(from state: ItemDetailViewStating) {
        guard let item = context?.value else { return }
        repository.update(item, with: ItemDetailUpdate(
            name: state.name,
            notes: state.notes,
            date: state.date,
            repeatState: state.repeatState,
            project: state.project
        ))
    }
}

// MARK: - ItemDetailViewControllerDelegate

extension ItemDetailController: ItemDetailViewControllerDelegate {
    func viewControllerWillAppear(_ viewController: ItemDetailViewControlling) {
        reload()
    }

    func viewControllerWillDismiss(_ viewController: ItemDetailViewControlling) {
        guard let item = context?.value, item.hasChanges else { return }
        save()
    }

    func viewController(_ viewController: ItemDetailViewControlling, performAction action: ItemDetailAction) {
        switch action {
        case .cancel: cancel()
        case .save: save()
        case .delete: delete()
        }
    }

    func viewController(_ viewController: ItemDetailViewControlling, updatedState state: ItemDetailViewStating) {
        updateItem(from: state)
    }
}

// MARK: - TodoItem

private extension TodoItem {
    var isEmpty: Bool {
        return (name == nil
                && notes == nil
                && date == nil
                && repeatState == .default
                && project == nil
                && blocking?.count ?? 0 == 0
                && blockedBy?.count ?? 0 == 0)
    }
}
