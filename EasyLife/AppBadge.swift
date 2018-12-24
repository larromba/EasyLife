import UIKit
import UserNotifications

protocol Badge: AnyObject {
    var number: Int { get set }
}

final class AppBadge: Badge {
    private let notificationCenter: UNUserNotificationCenter
    private let application: UIApplication
    var number: Int {
        get {
            return application.applicationIconBadgeNumber
        }
        set {
            notificationCenter.requestAuthorization(options: [.badge]) { granted, error in
                guard granted, error == nil else {
                    // TODO: granted?
                    return
                }
                DispatchQueue.main.async {
                    self.application.applicationIconBadgeNumber = newValue
                }
            }
        }
    }

    init(notificationCenter: UNUserNotificationCenter = .current(), application: UIApplication = .shared) {
        self.notificationCenter = notificationCenter
        self.application = application
    }
}
