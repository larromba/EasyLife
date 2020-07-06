import AsyncAwait
import UIKit
import UserNotifications

// sourcery: name = AppBadge
protocol Badge: AnyObject, Mockable {
    var number: Int { get }

    // sourcery: returnValue = Async<Void, Error>.success(())
    func setNumber(_ number: Int) -> Async<Void, Error>
}

final class AppBadge: Badge {
    private let notificationCenter: UNUserNotificationCenter
    private let application: UIApplication
    var number: Int {
        return application.applicationIconBadgeNumber
    }

    init(notificationCenter: UNUserNotificationCenter = .current(), application: UIApplication = .shared) {
        self.notificationCenter = notificationCenter
        self.application = application
    }

    func setNumber(_ number: Int) -> Async<Void, Error> {
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
