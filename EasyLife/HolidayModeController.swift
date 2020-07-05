import AsyncAwait
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
    private weak var delegate: HolidayModeControllerDelegate?

    func start() {
        print("TODO")
    }

    func setDelegate(_ delegate: HolidayModeControllerDelegate) {
        self.delegate = delegate
    }

    func controllerFinished(_ controller: HolidayModeControlling) {
        delegate?.controllerFinished(self)
    }
}
