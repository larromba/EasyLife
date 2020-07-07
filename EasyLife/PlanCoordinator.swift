import AsyncAwait
import UIKit

// sourcery: name = PlanCoordinator
protocol PlanCoordinating: Mockable {
    func start()
    func resetNavigation()
    func openNewTodoItem()
    func openFocusWithDate(_ date: Date)
}

final class PlanCoordinator: NSObject, PlanCoordinating {
    private let planController: PlanControlling
    private let planAlertController: AlertControlling
    private let itemDetailController: ItemDetailControlling
    private var itemDetailAlertController: AlertControlling?
    private let blockedByController: BlockedByControlling
    private var blockedByAlertController: AlertControlling?
    private let holidayController: HolidayControlling
    private let navigationController: UINavigationController
    private var context: TodoItemContext?
    private var lastNavigationStack = [UIViewController]()

    init(navigationController: UINavigationController, planController: PlanControlling,
         planAlertController: AlertControlling, itemDetailController: ItemDetailControlling,
         blockedByController: BlockedByControlling, holidayController: HolidayControlling) {
        self.navigationController = navigationController
        self.planController = planController
        self.planAlertController = planAlertController
        self.itemDetailController = itemDetailController
        self.blockedByController = blockedByController
        self.holidayController = holidayController
        super.init()
        onMain { navigationController.delegate = self } // warning thrown if set on bg thread
        planController.setDelegate(self)
        itemDetailController.setDelegate(self)
        blockedByController.setDelegate(self)
        holidayController.setDelegate(self)
    }

    func start() {
        planController.start()
    }

    func openNewTodoItem() {
        planController.openNewTodoItem()
    }

    func openFocusWithDate(_ date: Date) {
        planController.openFocusWithDate(date)
    }

    func resetNavigation() {
        itemDetailController.invalidate()
        blockedByController.invalidate()
        invalidate()
        navigationController.hardReset()
    }

    // MARK: - private

    private func isMovingBack(for viewController: UIViewController) -> Bool {
        return navigationController.viewControllers.contains(viewController)
    }

    private func invalidate() {
        itemDetailAlertController = nil
        blockedByAlertController = nil
        context = nil
    }
}

// MARK: - PlanControllerDelegate

extension PlanCoordinator: PlanControllerDelegate {
    func controller(_ controller: PlanControlling, handleContext context: TodoItemContext, sender: Segueable) {
        self.context = context
        sender.performSegue(withIdentifier: "openItemDetailViewController", sender: nil)
    }

    func controller(_ controller: PlanControlling, showAlert alert: Alert) {
        planAlertController.showAlert(alert)
    }

    func controllerRequestsHoliday(_ controller: PlanControlling) {
        holidayController.start()
    }

    func controllerRequestsFocus(_ controller: PlanControlling, withDate date: Date, sender: Segueable) {
        sender.performSegue(withIdentifier: "openFocusViewController", sender: date)
    }
}

// MARK: - ItemDetailControllerDelegate

extension PlanCoordinator: ItemDetailControllerDelegate {
    func controllerFinished(_ controller: ItemDetailControlling) {
        invalidate()
        navigationController.popViewController(animated: true)
    }

    func controller(_ controller: ItemDetailControlling, showAlert alert: Alert) {
        itemDetailAlertController?.showAlert(alert)
    }
}

extension PlanCoordinator: BlockedByControllerDelegate {
    func controller(_ controller: BlockedByControlling, showAlert alert: Alert) {
        blockedByAlertController?.showAlert(alert)
    }
}

// MARK: - HolidayControllerDelegate

extension PlanCoordinator: HolidayControllerDelegate {
    func controllerFinished(_ controller: HolidayControlling) {
        // 🦄
    }
}

// MARK: - UINavigationControllerDelegate

extension PlanCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController, animated: Bool) {
        let currentViewControllerStack = navigationController.viewControllers
        defer { lastNavigationStack = currentViewControllerStack }

        // if going backwards
        if lastNavigationStack.count > currentViewControllerStack.count {
            let movingFromViewController = lastNavigationStack.last
            switch movingFromViewController {
            case is ItemDetailViewControlling:
                itemDetailAlertController = nil
                context = nil
            case is BlockedByViewControlling:
                blockedByAlertController = nil
            default:
                assertionFailureIgnoreTests(
                    "unhandled vc: \(String(describing: movingFromViewController?.classForCoder))")
            }
            return
        }
        // if going forwards to ItemDetailViewControlling
        else if let viewController = viewController as? ItemDetailViewControlling {
            itemDetailAlertController = AlertController(presenter: viewController)
            itemDetailController.setViewController(viewController)
            if let context = context {
                itemDetailController.setContext(context)
            }
            itemDetailController.start()
        // if going forwards to BlockedByViewControlling
        } else if let viewController = viewController as? BlockedByViewControlling {
            blockedByAlertController = AlertController(presenter: viewController)
            blockedByController.setViewController(viewController)
            if let context = context {
                blockedByController.setContext(context)
            }
            blockedByController.start()
        } else {
            assertionFailureIgnoreTests("unhandled vc: \(viewController.classForCoder)")
        }
    }
}
