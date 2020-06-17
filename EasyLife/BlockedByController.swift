import AsyncAwait
import Foundation

// sourcery: name = BlockedByController
protocol BlockedByControlling: TodoItemContexting, Mockable {
    func setViewController(_ viewController: BlockedByViewControlling)
    func setAlertController(_ alertController: AlertControlling)
}

final class BlockedByController: BlockedByControlling {
    private weak var viewController: BlockedByViewControlling?
    private var alertController: AlertControlling?
    private let repository: BlockedByRepositoring
    private var context: EditContext<TodoItem>?

    init(repository: BlockedByRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: BlockedByViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setAlertController(_ alertController: AlertControlling) {
        self.alertController = alertController
    }

    func setContext(_ context: TodoItemContext) {
        let item: TodoItem
        switch context {
        case .existing(let value):
            item = value
        case let .new(value, context):
            item = value
            repository.setChildContext(context)
        }
        self.context = EditContext(value: item)
        async({
            let items = try await(self.repository.fetchItems(for: item))
            onMain {
                self.viewController?.viewState = BlockedByViewState(item: item, items: items)
                self.viewController?.reload()
            }
        }, onError: { error in
            onMain { self.alertController?.showAlert(Alert(error: error)) }
        })
    }
}

// MARK: - BlockedByViewControllerDelegate

extension BlockedByController: BlockedByViewControllerDelegate {
    func viewControllerWillDismiss(_ viewController: BlockedByViewControlling) {
        guard let item = context?.value, let data = viewController.viewState?.data else { return }
        repository.update(item, with: data)
    }

    func viewController(_ viewController: BlockedByViewControlling, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard let viewState = viewController.viewState else { return }
        var data = viewState.data
        data[indexPath.row].isBlocking = !data[indexPath.row].isBlocking
        viewController.viewState = viewState.copy(data: data)
        viewController.reloadRows(at: indexPath)
    }
}
