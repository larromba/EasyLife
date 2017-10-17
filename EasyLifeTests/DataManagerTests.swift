//
//  DataManagerTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 02/09/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class DataManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // migrations
    func test1() {
        let bundle = Bundle(for: DataManagerTests.self)
        do {
            var url = bundle.url(forResource: "EasyLife", withExtension: "sqlite")
            try _ = NSPersistentContainer.test(url: url)
            
            url = bundle.url(forResource: "EasyLife 1.3.0", withExtension: "sqlite")
            try _ = NSPersistentContainer.test(url: url)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
