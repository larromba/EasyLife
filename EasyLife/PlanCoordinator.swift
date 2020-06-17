import AsyncAwait
import UIKit

// sourcery: name = PlanCoordinator
protocol PlanCoordinating: Mockable {
    func start()
}

final class PlanCoordinator: NSObject, PlanCoordinating {
    private let planController: PlanControlling
    private let itemDetailController: ItemDetailControlling
    private let blockedByController: BlockedByControlling
    private let navigationController: UINavigationController
    private var context: TodoItemContext?
    private var lastNavigationStack = [UIViewController]()

    init(navigationController: UINavigationController, planController: PlanControlling,
         itemDetailController: ItemDetailControlling, blockedByController: BlockedByControlling) {
        self.navigationController = navigationController
        self.planController = planController
        self.itemDetailController = itemDetailController
        self.blockedByController = blockedByController
        super.init()
        onMain { navigationController.delegate = self } // warning thrown if set on bg thread
        planController.setDelegate(self)
        itemDetailController.setDelegate(self)
    }

    func start() {
        planController.start()
    }

    // MARK: - private

    private func isMovingBack(for viewController: UIViewController) -> Bool {
        return navigationController.viewControllers.contains(viewController)
    }
}

// MARK: - PlanControllerDelegate

extension PlanCoordinator: PlanControllerDelegate {
    func controller(_ controller: PlanControlling, handleContext context: TodoItemContext, sender: Segueable) {
        self.context = context
        sender.performSegue(withIdentifier: "openItemDetailViewController", sender: self)
    }
}

// MARK: - ItemDetailControllerDelegate

extension PlanCoordinator: ItemDetailControllerDelegate {
    func controllerFinished(_ controller: ItemDetailControlling) {
        context = nil
        navigationController.popViewController(animated: true)
    }
}

// MARK: - UINavigationControllerDelegate

extension PlanCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        defer { lastNavigationStack = navigationController.viewControllers }

        // if going back, ignore
        guard !lastNavigationStack.contains(viewController) else { return }

        // if first vc, reset the editing context
        guard !(viewController is PlanViewController) else {
            context = nil
            return
        }

        // if other vcs, pass through the context
        if let viewController = viewController as? ItemDetailViewControlling {
            itemDetailController.setViewController(viewController)
            itemDetailController.setAlertController(AlertController(presenter: viewController))
            if let context = context {
                itemDetailController.setContext(context)
            }
        } else if let viewController = viewController as? BlockedByViewControlling {
            blockedByController.setViewController(viewController)
            blockedByController.setAlertController(AlertController(presenter: viewController))
            if let context = context {
                blockedByController.setContext(context)
            }
        } else {
            assertionFailureIgnoreTests("unhandled viewController: \(viewController.classForCoder)")
        }
    }
}
