//
//  BadgeManager.swift
//  EasyLife
//
//  Created by Lee Arromba on 30/05/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit
import UserNotifications

class Badge {
    var notificationCenter: UNUserNotificationCenter
    var number: Int {
        get {
            return UIApplication.shared.applicationIconBadgeNumber
        }
        set {
            notificationCenter.requestAuthorization(options: [.badge]) {
                (granted, error) in
                guard granted, error == nil else {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    return
                }
                UIApplication.shared.applicationIconBadgeNumber = newValue
            }
        }
    }
    
    init() {
        notificationCenter = UNUserNotificationCenter.current()
    }
}
