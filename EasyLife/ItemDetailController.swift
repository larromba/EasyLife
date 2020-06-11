import AsyncAwait
import Foundation

// sourcery: name = ItemDetailController
protocol ItemDetailControlling: Mockable {
    func setViewController(_ viewController: ItemDetailViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setDelegate(_ delegate: ItemDetailControllerDelegate)
    func setContext(_ context: PlanItemContext)
}

protocol ItemDetailControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ItemDetailControlling)
}

final class ItemDetailController: ItemDetailControlling {
    private weak var viewController: ItemDetailViewControlling?
    private let repository: ItemDetailRepositoring
    private var alertController: AlertControlling?
    private var editContext: ObjectContext<TodoItem>?
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

    func setContext(_ context: PlanItemContext) {
        switch context {
        case .existing(let item):
            viewController?.viewState = ItemDetailViewState(item: item, isNew: false, items: [], projects: [])
            editContext = ObjectContext(object: item)
            reload()
        case let .new(item, context):
            viewController?.viewState = ItemDetailViewState(item: item, isNew: true, items: [], projects: [])
            editContext = ObjectContext(object: item)
            repository.setChildContext(context)
        }
    }

    // MARK: - private

    private func showCancelAlert() {
        let alert = Alert(
            title: L10n.unsavedChangesTitle,
            message: L10n.unsavedChangesMessage,
            cancel: Alert.Action(title: L10n.unsavedChangesNo, handler: {
                self.delegate?.controllerFinished(self)
            }),
            actions: [Alert.Action(title: L10n.unsavedChangesYes, handler: {
                self.save()
            })],
            textField: nil
        )
        alertController?.showAlert(alert)
    }

    private func reload() {
        guard let item = editContext?.object else { return }
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
            editContext = nil
            delegate?.controllerFinished(self)
        }
    }

    private func hasUnsavedChanges() -> Bool {
        if let item = editContext?.object, !item.isEmpty {
            return true
        } else {
            return false
        }
    }

    private func save() {
        guard let item = editContext?.object else { return }
        async({
            _ = try await(self.repository.save(item: item))
            onMain {
                self.delegate?.controllerFinished(self)
            }
        }, onError: { error in
            self.alertController?.showAlert(Alert(error: error))
        })
    }

    private func delete() {
        guard let item = editContext?.object else { return }
        async({
            _ = try await(self.repository.delete(item: item))
            onMain {
                self.delegate?.controllerFinished(self)
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }

    private  func updateItem(from state: ItemDetailViewStating) {
        guard let item = editContext?.object else { return }
        item.name = state.name
        item.notes = state.notes
        item.date = state.date
        item.repeatState = state.repeatState
        item.project = state.project
    }
}

// MARK: - ItemDetailViewControllerDelegate

extension ItemDetailController: ItemDetailViewControllerDelegate {
    func viewControllerWillAppear(_ viewController: ItemDetailViewControlling) {
        reload()
    }

    func viewControllerWillDismiss(_ viewController: ItemDetailViewControlling) {
        guard let item = editContext?.object, item.hasChanges else { return }
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
                && repeatState == RepeatState.none
                && project == nil
                && blocking?.count ?? 0 == 0
                && blockedBy?.count ?? 0 == 0)
    }
}
