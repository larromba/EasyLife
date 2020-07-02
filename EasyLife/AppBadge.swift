import AsyncAwait
import UIKit
import UserNotifications

// sourcery: name = Badge
protocol Badging: AnyObject, Mockable {
    var number: Int { get }

    // sourcery: returnValue = Async.success(())
    func setNumber(_ number: Int) -> Async<Void>
}

final class AppBadge: Badging {
    private let notificationCenter: UNUserNotificationCenter
    private let application: UIApplication
    var number: Int {
        return application.applicationIconBadgeNumber
    }

    init(notificationCenter: UNUserNotificationCenter = .current(), application: UIApplication = .shared) {
        self.notificationCenter = notificationCenter
        self.application = application
    }

    func setNumber(_ number: Int) -> Async<Void> {
        return Async { completion in
            #if DEBUG
            if __isSnapshot { return completion(.success(())) }
            #endif
            self.notificationCenter.requestAuthorization(options: [.badge]) { granted, error in
                if let error = error {
                    completion(.failure(NotificationAuthorizationError.frameworkError(error)))
                    return
                }
                guard granted else {
                    completion(.failure(NotificationAuthorizationError.unauthorized))
                    return
                }
                onMain { self.application.applicationIconBadgeNumber = number }
                completion(.success(()))
            }
        }
    }
}
