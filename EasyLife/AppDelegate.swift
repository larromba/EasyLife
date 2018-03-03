//
//  AppDelegate.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var dataManager: DataManager
    var analytics: Analytics

    override init() {
        dataManager = DataManager.shared
        analytics = Analytics.shared
        super.init()
        setupNotifications()
    }
    
    deinit {
        tearDownNotifications()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        log("\nDEBUG BUILD")
        log("open \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? "nil")\n")
        
        Fabric.with([Crashlytics.self])
        
        do {
            try analytics.setup()
        } catch _ {
            log("analytics setup failed")
        }
        analytics.startSession()
        dataManager.load()

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        analytics.endSession()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        analytics.startSession()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        dataManager.save(context: dataManager.mainContext)
    }
    
    // MARK: - private
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveFatalError(_:)), name: .applicationDidReceiveFatalError, object: nil)
    }
    
    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: .applicationDidReceiveFatalError, object: nil)
    }
    
    @objc private func applicationDidReceiveFatalError(_ notification: Notification) {
        log("applicationDidReceiveFatalError \(notification.object ?? "nil")")
        if let window = window, let error = notification.object as? Error, let fatalViewController = UIStoryboard.components.instantiateViewController(withIdentifier: "FatalViewController") as? FatalViewController {
            fatalViewController.error = error
            window.rootViewController = fatalViewController
            Analytics.shared.sendErrorEvent(error, classId: AppDelegate.self)
        }
    }
}
