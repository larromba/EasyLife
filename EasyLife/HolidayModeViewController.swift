import UIKit

// sourcery: name = HolidayModeViewController
protocol HolidayModeViewControlling: Mockable {
    func setDelegate(_ delegate: HolidayModeViewControllerDelegate)
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

protocol HolidayModeViewControllerDelegate: AnyObject {
    func viewControllerTapped(_ viewController: HolidayModeViewControlling)
}

final class HolidayModeViewController: UIViewController, HolidayModeViewControlling {
    weak var delegate: HolidayModeViewControllerDelegate?

    func setDelegate(_ delegate: HolidayModeViewControllerDelegate) {
        self.delegate = delegate
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.viewControllerTapped(self)
    }
}
