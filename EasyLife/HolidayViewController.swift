import UIKit

// sourcery: name = HolidayViewController
protocol HolidayViewControlling: AnyObject, ViewControllerCastable, Dismissible, Mockable {
    // sourcery: value = UIModalPresentationStyle.fullScreen
    var modalPresentationStyle: UIModalPresentationStyle { get set }
    // sourcery: value = UIModalTransitionStyle.crossDissolve
    var modalTransitionStyle: UIModalTransitionStyle { get set }

    func setDelegate(_ delegate: HolidayViewControllerDelegate)
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
