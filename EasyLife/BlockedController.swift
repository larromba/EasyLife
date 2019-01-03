import AsyncAwait
import Foundation

// sourcery: name = BlockedController
protocol BlockedControlling: Mockable {
    func setViewController(_ viewController: BlockedViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setItem(_ item: TodoItem)
}

final class BlockedController: BlockedControlling {
    private weak var viewController: BlockedViewControlling?
    private var alertController: AlertControlling?
    private let repository: BlockedRepositoring
    private var editContext: ObjectContext<TodoItem>?

    init(repository: BlockedRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: BlockedViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setItem(_ item: TodoItem) {
        editContext = ObjectContext(object: item)
        async({
            let items = try await(self.repository.fetchItems(for: item))
            onMain {
                self.viewController?.viewState = BlockedViewState(item: item, items: items)
            }
        }, onError: { error in
            self.alertController?.showAlert(Alert(error: error))
        })
    }
}

// MARK: - BlockedViewControllerDelegate

extension BlockedController: BlockedViewControllerDelegate {
    func viewControllerWillDismiss(_ viewController: BlockedViewControlling) {
        guard let item = editContext?.object, let viewState = viewController.viewState else { return }
        viewState.data.forEach {
            if $0.isBlocking {
                item.addToBlockedBy($0.object)
            } else {
                item.removeFromBlockedBy($0.object)
            }
        }
    }
}
