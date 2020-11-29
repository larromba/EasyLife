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
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

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
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationWillResignActive(_:)),
                                       name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func tearDownNotifications() {
        notificationCenter.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
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
