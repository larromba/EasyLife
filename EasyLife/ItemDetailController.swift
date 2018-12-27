import AsyncAwait
import Foundation

protocol ItemDetailControlling {
    func setViewController(_ viewController: ItemDetailViewControlling)
    func setDelegate(_ delegate: ItemDetailControllerDelegate)
    func setItem(_ item: TodoItem)
}

protocol ItemDetailControllerDelegate: AnyObject {
    func controllerFinished(_ controller: ItemDetailController)
}

final class ItemDetailController: ItemDetailControlling {
    private var viewController: ItemDetailViewControlling?
    private let repository: ItemDetailRepositoring
    private var editContext: Context<TodoItem>?
    private weak var delegate: ItemDetailControllerDelegate?

    init(repository: ItemDetailRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: ItemDetailViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setDelegate(_ delegate: ItemDetailControllerDelegate) {
        self.delegate = delegate
    }

    func setItem(_ item: TodoItem) {
        editContext = Context(object: item)
        async({
            let items = try await(self.repository.fetchItems(for: item))
            let projects = try await(self.repository.fetchProjects(for: item))
            onMain {
                self.viewController?.viewState = ItemDetailViewState(item: item, items: items, projects: projects)
            }
        }, onError: { _ in
            // TODO: handle
        })
    }
}

// MARK: - ItemDetailViewControllerDelegate

extension ItemDetailController: ItemDetailViewControllerDelegate {
    func viewController(_ viewController: ItemDetailViewControlling, performAction action: ItemDetailAction) {
        guard let item = editContext?.object else { return }
        async({
            switch action {
            case .save: _ = try await(self.repository.save(item: item))
            case .delete: _ = try await(self.repository.delete(item: item))
            }
            onMain {
                self.delegate?.controllerFinished(self)
            }
        }, onError: { _ in
            // TODO: handle
        })
    }

    func viewController(_ viewController: ItemDetailViewControlling, updatedState state: ItemDetailViewState) {
        guard let item = editContext?.object else { return }
        item.name = state.name
        item.notes = state.notes
        item.date = state.date
        item.repeatState = state.repeatState
        item.project = state.project
        state.blockable.forEach {
            if $0.isBlocked {
                item.addToBlockedBy($0.item)
            } else {
                item.removeFromBlockedBy($0.item)
            }
        }
    }
}
