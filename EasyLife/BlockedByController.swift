import AsyncAwait
import Foundation

// sourcery: name = BlockedByController
protocol BlockedByControlling: Mockable {
    func setViewController(_ viewController: BlockedByViewControlling)
    func setAlertController(_ alertController: AlertControlling)
    func setContext(_ context: PlanItemContext)
}

final class BlockedByController: BlockedByControlling {
    private weak var viewController: BlockedByViewControlling?
    private var alertController: AlertControlling?
    private let repository: BlockedByRepositoring
    private var editContext: ObjectContext<TodoItem>?

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

    func setContext(_ context: PlanItemContext) {
        switch context {
        case .existing(let item):
            editContext = ObjectContext(object: item)
        case .new(let item, _):
            editContext = ObjectContext(object: item)
        }
        guard let item = editContext?.object else { return }
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
        guard let item = editContext?.object, let viewState = viewController.viewState else { return }
        viewState.data.forEach {
            if $0.isBlocking {
                item.addToBlockedBy($0.object)
            } else {
                item.removeFromBlockedBy($0.object)
            }
        }
    }

    func viewController(_ viewController: BlockedByViewControlling, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard let viewState = viewController.viewState else { return }
        var data = viewState.data
        data[indexPath.row].isBlocking = !data[indexPath.row].isBlocking
        viewController.viewState = viewState.copy(data: data)
        viewController.reloadRows(at: indexPath)
    }
}
