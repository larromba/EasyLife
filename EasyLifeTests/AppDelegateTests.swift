//
//  AppDelegateTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 20/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class AppDelegateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        UIView.setAnimationsEnabled(false)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }
    
    // show fatal vc if notification thrown
    func test1() {
        // mocks
        let error = NSError(domain: "", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "",
            ])
        
        // test
        NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)
        XCTAssertNotNil(UIApplication.shared.keyWindow?.rootViewController as? FatalViewController)
    }
}
