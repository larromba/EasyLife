import AsyncAwait
import Logging
import UIKit
import UserNotifications

// sourcery: name = AlarmNotificationHandler
protocol AlarmNotificationHandling: AnyObject, Mockable {
    func start(in timeInterval: TimeInterval)
    func stop()
    // sourcery: returnValue = Async<Date?, Error>.success(nil)
    func currentNotificationDate() -> Async<Date?, Error>
}

final class AlarmNotificationHandler: AlarmNotificationHandling {
    private let notificationCenter: UNUserNotificationCenter
    private let application: UIApplication
    private let identifier = "focus-mode-alarm"
    private let categoryIdentifier = "TIMER_EXPIRED"

    init(notificationCenter: UNUserNotificationCenter = .current(), application: UIApplication = .shared) {
        self.notificationCenter = notificationCenter
        self.application = application
    }

    func start(in timeInterval: TimeInterval) {
        async({
            try await(self.requestAuthentication())
            let date = Date().addingTimeInterval(timeInterval)
            let request = self.makeRequest(for: date)
            self.notificationCenter.add(request) { error in
                if let error = error {
                    logError(error.localizedDescription)
                }
            }
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }

    func stop() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func currentNotificationDate() -> Async<Date?, Error> {
        return Async { completion in
            self.notificationCenter.getPendingNotificationRequests { [weak self] requests in
                guard let request = requests.first(where: { $0.identifier == self?.identifier }),
                    let trigger = request.trigger as? UNCalendarNotificationTrigger,
                    let date = Calendar.current.date(from: trigger.dateComponents) else {
                        completion(.success(nil))
                        return
                }
                completion(.success(date))
            }
        }
    }

    // MARK: - private

    private func makeRequest(for date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = L10n.alarmNotificationTitle
        content.body = L10n.alarmNotificationBody
        content.categoryIdentifier = self.categoryIdentifier
        let dateComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second, .timeZone]
        let components = Calendar.current.dateComponents(dateComponents, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: self.identifier, content: content, trigger: trigger)
    }

    private func requestAuthentication() -> Async<Void, Error> {
        return Async { completion in
            self.notificationCenter.requestAuthorization(options: [.alert]) { granted, error in
                if let error = error {
                    completion(.failure(NotificationAuthorizationError.frameworkError(error)))
                    return
                }
                guard granted else {
                    completion(.failure(NotificationAuthorizationError.unauthorized))
                    return
                }
                completion(.success(()))
            }
        }
    }
}
