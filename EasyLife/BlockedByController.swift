import AsyncAwait
import Foundation

// sourcery: name = BlockedByController
protocol BlockedByControlling: TodoItemContexting, Mockable {
    func setViewController(_ viewController: BlockedByViewControlling)
    func setDelegate(_ delegate: BlockedByControllerDelegate)
    func invalidate()
}

protocol BlockedByControllerDelegate: AnyObject {
    func controller(_ controller: BlockedByControlling, showAlert alert: Alert)
}

final class BlockedByController: BlockedByControlling {
    private let repository: BlockedByRepositoring
    private var context: EditContext<TodoItem>?
    private weak var viewController: BlockedByViewControlling?
    private weak var delegate: BlockedByControllerDelegate?

    init(repository: BlockedByRepositoring) {
        self.repository = repository
    }

    func setViewController(_ viewController: BlockedByViewControlling) {
        self.viewController = viewController
        viewController.setDelegate(self)
    }

    func setDelegate(_ delegate: BlockedByControllerDelegate) {
        self.delegate = delegate
    }

    func setContext(_ context: TodoItemContext) {
        let item: TodoItem
        switch context {
        case let .new(value, context):
            item = value
            repository.setContext(context)
        case let .existing(value, context):
            item = value
            repository.setContext(context)
        }
        self.context = EditContext(value: item)
        async({
            let items = try await(self.repository.fetchItems(for: item))
            onMain {
                self.viewController?.viewState = BlockedByViewState(item: item, items: items)
                self.viewController?.reload()
            }
        }, onError: { error in
            onMain { self.delegate?.controller(self, showAlert: Alert(error: error)) }
        })
    }

    func invalidate() {
        context = nil
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
