import Logging
import UIKit

final class FatalErrorHandler {
    private let window: UIWindow
    private let notificationCenter: NotificationCenter

    init(window: UIWindow, notificationCenter: NotificationCenter = .default) {
        self.window = window
        self.notificationCenter = notificationCenter
        setupNotifications()
    }

    // MARK: - private

    private func setupNotifications() {
        notificationCenter.addObserver(self, selector: #selector(applicationDidReceiveFatalError(_:)),
                                       name: .applicationDidReceiveFatalError, object: nil)
    }

    @objc
    private func applicationDidReceiveFatalError(_ notification: Notification) {
        guard let error = notification.object as? Error else {
            assertionFailure("expected Error")
            return
        }
        logError("applicationDidReceiveFatalError: \(error.localizedDescription)")
        let fatalViewController: FatalViewController = UIStoryboard.components.instantiateViewController()
        fatalViewController.viewState = FatalViewState(error: error)
        window.rootViewController = fatalViewController
    }
}
