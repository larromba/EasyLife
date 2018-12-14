import Logging
import UIKit

final class FatalErrorHandler {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        setupNotifications()
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveFatalError(_:)),
                                               name: .applicationDidReceiveFatalError, object: nil)
    }

    @objc
    private func applicationDidReceiveFatalError(_ notification: Notification) {
        log("applicationDidReceiveFatalError \(notification.object ?? "nil")")
        if let error = notification.object as? Error,
            let fatalViewController = UIStoryboard.components
                .instantiateViewController(withIdentifier: "FatalViewController")as? FatalViewController {
                    fatalViewController.error = error
                    window.rootViewController = fatalViewController
        }
    }
}
