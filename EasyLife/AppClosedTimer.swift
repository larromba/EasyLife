import UIKit

// sourcery: name = AppClosedTimer
protocol AppClosedTiming {
    func setDelegate(_ delegate: AppClosedTimerDelegate)
    func startListening()
    func stopListening()
}

protocol AppClosedTimerDelegate: AnyObject {
    func timer(_ timer: AppClosedTiming, isReopenedAfterTime time: TimeInterval)
}

final class AppClosedTimer: AppClosedTiming {
    private var resignActiveDate: Date?
    private weak var delegate: AppClosedTimerDelegate?

    func setDelegate(_ delegate: AppClosedTimerDelegate) {
        self.delegate = delegate
    }

    func startListening() {
        setupNotifications()
    }

    func stopListening() {
        tearDownNotifications()
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)),
                                               name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification,
                                                  object: nil)
    }

    @objc
    private func applicationDidEnterForeground(_ notification: Notification) {
        guard let date = resignActiveDate else { return }
        resignActiveDate = nil
        delegate?.timer(self, isReopenedAfterTime: Date().timeIntervalSince(date))
    }

    @objc
    private func applicationWillResignActive(_ notification: Notification) {
        resignActiveDate = Date()
    }
}
