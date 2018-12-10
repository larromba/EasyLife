//
//  FatalError.swift
//  EasyLife
//
//  Created by Lee Arromba on 02/08/2018.
//  Copyright © 2018 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class FatalErrorHandler {
	private let window: UIWindow
	private let analytics: Analytics

	init(window: UIWindow, analytics: Analytics) {
		self.window = window
		self.analytics = analytics
		setupNotifications()
	}

	// MARK: - private

	private func setupNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(applicationDidReceiveFatalError(_:)), name: .applicationDidReceiveFatalError, object: nil)
	}

	@objc private func applicationDidReceiveFatalError(_ notification: Notification) {
		log("applicationDidReceiveFatalError \(notification.object ?? "nil")")
		if let error = notification.object as? Error, let fatalViewController = UIStoryboard.components.instantiateViewController(withIdentifier: "FatalViewController") as? FatalViewController {
			fatalViewController.error = error
			window.rootViewController = fatalViewController
			analytics.sendErrorEvent(error, classId: AppDelegate.self)
		}
	}
}
