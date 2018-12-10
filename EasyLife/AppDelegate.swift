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
	var window: UIWindow? {
		didSet {
			guard let window = window else {
				fatalErrorHandler = nil
				return
			}
			fatalErrorHandler = FatalErrorHandler(window: window, analytics: analytics)
		}
	}
    var dataManager: DataManager
    var analytics: Analytics
	var fatalErrorHandler: FatalErrorHandler?

    override init() {
        dataManager = DataManager.shared
        analytics = Analytics.shared
        super.init()
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
}
