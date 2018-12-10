//
//  FatalErrorHandlerTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 20/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class FatalErrorHandlerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }
    
    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }
    
    func testShowFatalViewControllerOnNotification() {
        // mocks
        let error = NSError(domain: "", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "",
            ])
        
        // test
        NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)
        XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController as? FatalViewController)
    }
}
