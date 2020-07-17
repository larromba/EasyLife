import UIKit

// sourcery: name = HolidayCoordinator
protocol HolidayCoordinating: Mockable {
    func setViewController(_ viewController: HolidayViewControlling)
    func start()
}

final class HolidayCoordinator: HolidayCoordinating {
    private let holidayController: HolidayControlling
    private weak var rootViewController: HolidayViewControlling?

    init(holidayController: HolidayControlling) {
        self.holidayController = holidayController
        holidayController.setDelegate(self)
    }

    func setViewController(_ viewController: HolidayViewControlling) {
        rootViewController = viewController
        holidayController.setViewController(viewController)
    }

    func start() {
        holidayController.start()
    }
}

// MARK: - HolidayControllerDelegate

extension HolidayCoordinator: HolidayControllerDelegate {
    func controllerFinished(_ controller: HolidayControlling) {
        rootViewController?.dismiss(animated: true, completion: nil)
    }
}
