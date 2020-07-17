import AsyncAwait
import Logging
import UIKit

// sourcery: name = AppRouter
protocol AppRouting: Mockable {
    func start()
    func routeToNewTodoItem()
}

final class AppRouter: AppRouting {
    private let planCoordinator: PlanCoordinating
    private let focusCoordinator: FocusCoordinating
    private let archiveCoordinator: ArchiveCoordinating
    private let projectsCoordinator: ProjectsCoordinating
    private let holidayCoordinator: HolidayCoordinating
    private let alarmNotificationHandler: AlarmNotificationHandling

    init(planCoordinator: PlanCoordinating, focusCoordinator: FocusCoordinating,
         archiveCoordinator: ArchiveCoordinating, projectsCoordinator: ProjectsCoordinating,
         holidayCoordinator: HolidayCoordinating, alarmNotificationHandler: AlarmNotificationHandling) {
        self.planCoordinator = planCoordinator
        self.focusCoordinator = focusCoordinator
        self.archiveCoordinator = archiveCoordinator
        self.projectsCoordinator = projectsCoordinator
        self.holidayCoordinator = holidayCoordinator
        self.alarmNotificationHandler = alarmNotificationHandler
        planCoordinator.setDelegate(self)
    }

    func start() {
        planCoordinator.start()
        async({
            guard let date = try await(self.alarmNotificationHandler.currentNotificationDate()) else { return }
            onMain { self.routeToFocusWithDate(date: date) }
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }

    func routeToNewTodoItem() {
        resetAllNavigation()
        planCoordinator.openNewTodoItem()
    }

    // MARK: - StoryboardRouting

    func handleSegue(_ segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else { return }
        if let viewController = navigationController.viewControllers.first as? ProjectsViewControlling {
            projectsCoordinator.setViewController(viewController)
            projectsCoordinator.setNavigationController(navigationController)
            projectsCoordinator.setAlertController(AlertController(presenter: viewController))
            projectsCoordinator.start()
        } else if let viewController = navigationController.viewControllers.first as? ArchiveViewControlling {
            archiveCoordinator.setViewController(viewController)
            archiveCoordinator.setNavigationController(navigationController)
            archiveCoordinator.setAlertController(AlertController(presenter: viewController))
            archiveCoordinator.start()
        } else if let viewController = navigationController.viewControllers.first as? FocusViewControlling {
            focusCoordinator.setViewController(viewController)
            focusCoordinator.setNavigationController(navigationController)
            focusCoordinator.setAlertController(AlertController(presenter: viewController))
            if let date = sender as? Date {
                focusCoordinator.setTriggerDate(date)
            }
            focusCoordinator.start()
        } else {
            assertionFailure("unhandled route for view controller")
        }
    }

    // MARK: - private

    private func resetAllNavigation() {
        planCoordinator.resetNavigation()
        focusCoordinator.resetNavigation()
        archiveCoordinator.resetNavigation()
        projectsCoordinator.resetNavigation()
    }

    private func routeToFocusWithDate(date: Date) {
        resetAllNavigation()
        planCoordinator.openFocusWithDate(date)
    }
}

// MARK: - PlanCoordinating

extension AppRouter: PlanCoordinatorDelegate {
    func coordinatorRequestsHoliday(_ coordinator: PlanCoordinating) {
        let viewController: HolidayViewController = UIStoryboard.components.instantiateViewController()
        holidayCoordinator.setViewController(viewController)
        holidayCoordinator.start()
    }

    func coordinator(_ coordinator: PlanCoordinating, handleSegue segue: UIStoryboardSegue, sender: Any?) {
        handleSegue(segue, sender: sender)
    }
}
