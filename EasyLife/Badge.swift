import UIKit
import UserNotifications

class Badge {
    var notificationCenter: UNUserNotificationCenter
    var number: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            notificationCenter.requestAuthorization(options: [.badge]) { granted, error in
                DispatchQueue.main.async {
                    guard granted, error == nil else {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                        return
                    }
                    UIApplication.shared.applicationIconBadgeNumber = newValue
                }
            }
        }
    }

    init() {
        notificationCenter = UNUserNotificationCenter.current()
    }
}
