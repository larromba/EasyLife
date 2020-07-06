import AsyncAwait
import Logging
import UIKit

// sourcery: name = HolidayController
protocol HolidayControlling: Mockable {
    func start()
    func setDelegate(_ delegate: HolidayControllerDelegate)
}

protocol HolidayControllerDelegate: AnyObject {
    func controllerFinished(_ controller: HolidayControlling)
}

final class HolidayController: HolidayControlling {
    private let badge: Badge
    private let application: UIApplication
    private var viewController: HolidayViewControlling?
    private let holidayRepository: HolidayRepositoring
    private weak var delegate: HolidayControllerDelegate?
    private weak var presenter: Presentable?

    init(presenter: Presentable, holidayRepository: HolidayRepositoring, badge: Badge,
         application: UIApplication = .shared) {
        self.presenter = presenter
        self.holidayRepository = holidayRepository
        self.application = application
        self.badge = badge
    }

    func start() {
        let viewController: HolidayViewController = UIStoryboard.components.instantiateViewController()
        holidayRepository.isEnabled = true
        viewController.setDelegate(self)
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        presenter?.present(viewController, animated: true, completion: nil)
        setIsShortcutsEnabled(false)
        clearNotifications()
    }

    func setDelegate(_ delegate: HolidayControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func setIsShortcutsEnabled(_ isEnabled: Bool) {
        application.shortcutItems = isEnabled ? ShortcutItem.display.map { $0.item } : nil
    }

    private func clearNotifications() {
        async({
            try await(self.badge.setNumber(0))
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }
}

// MARK: - HolidayControllerDelegate

extension HolidayController: HolidayViewControllerDelegate {
    func viewControllerTapped(_ viewController: HolidayViewControlling) {
        holidayRepository.isEnabled = false
        setIsShortcutsEnabled(true)
        viewController.dismiss(animated: true, completion: nil)
        delegate?.controllerFinished(self)
    }
}
