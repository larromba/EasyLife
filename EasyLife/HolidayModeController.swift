import AsyncAwait
import Logging
import UIKit

// sourcery: name = HolidayModeController
protocol HolidayModeControlling: Mockable {
    func start()
    func setDelegate(_ delegate: HolidayModeControllerDelegate)
}

protocol HolidayModeControllerDelegate: AnyObject {
    func controllerFinished(_ controller: HolidayModeControlling)
}

final class HolidayModeController: HolidayModeControlling {
    private let badge: Badge
    private let application: UIApplication
    private var viewController: HolidayModeViewControlling?
    private var context: HolidayContext?
    private weak var delegate: HolidayModeControllerDelegate?
    private weak var presenter: Presentable?

    init(presenter: Presentable, badge: Badge, application: UIApplication = .shared) {
        self.presenter = presenter
        self.application = application
        self.badge = badge
    }

    func start() {
        guard let viewController = UIStoryboard.components
            .instantiateViewController(withIdentifier: "HolidayModeViewController") as? HolidayModeViewController else {
                return
        }
        viewController.setDelegate(self)
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        presenter?.present(viewController, animated: true, completion: nil)
        context = HolidayContext(shortcuts: application.shortcutItems, badgeNumber: badge.number)
        application.shortcutItems = nil
        async({
            try await(self.badge.setNumber(0))
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }

    func setDelegate(_ delegate: HolidayModeControllerDelegate) {
        self.delegate = delegate
    }
}

// MARK: - HolidayModeControllerDelegate

extension HolidayModeController: HolidayModeViewControllerDelegate {
    func viewControllerTapped(_ viewController: HolidayModeViewControlling) {
        guard let context = context else { return }
        self.context = nil
        self.application.shortcutItems = context.shortcuts
        async({
            try await(self.badge.setNumber(context.badgeNumber))
        }, onError: { error in
            logError(error.localizedDescription)
        })
        viewController.dismiss(animated: true, completion: nil)
        delegate?.controllerFinished(self)
    }
}
