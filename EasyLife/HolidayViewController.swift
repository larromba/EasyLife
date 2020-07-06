import UIKit

// sourcery: name = HolidayViewController
protocol HolidayViewControlling: Mockable {
    func setDelegate(_ delegate: HolidayViewControllerDelegate)
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

protocol HolidayViewControllerDelegate: AnyObject {
    func viewControllerTapped(_ viewController: HolidayViewControlling)
}

final class HolidayViewController: UIViewController, HolidayViewControlling {
    private weak var delegate: HolidayViewControllerDelegate?

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        delegate?.viewControllerTapped(self)
    }

    func setDelegate(_ delegate: HolidayViewControllerDelegate) {
        self.delegate = delegate
    }
}
