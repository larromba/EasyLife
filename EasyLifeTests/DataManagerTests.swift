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
    func testMigrations() {
        // prepare
        let bundle = Bundle(for: DataManagerTests.self)
        do {
            // tests
            var url = bundle.url(forResource: "EasyLife", withExtension: "sqlite")
            try _ = NSPersistentContainer.test(url: url)
            
            url = bundle.url(forResource: "EasyLife 1.3.0", withExtension: "sqlite")
            try _ = NSPersistentContainer.test(url: url)

            url = bundle.url(forResource: "EasyLife 1.5.0", withExtension: "sqlite")
            try _ = NSPersistentContainer.test(url: url)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testInsert() {
        // mocks
        let dataManager = DataManager()
        let container = try! NSPersistentContainer.test()

        // prepare
        dataManager.persistentContainer = container

        // test
        let item = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)
        XCTAssertNotNil(item)
    }

    func testCopy() {
        // mocks
        let dataManager = DataManager()
        let container = try! NSPersistentContainer.test()

        // prepare
        dataManager.persistentContainer = container
        let item = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        item.name = "test"

        // test
        let copy = dataManager.copy(item, context: dataManager.mainContext) as? TodoItem
        XCTAssertNotNil(item)
        XCTAssertEqual(item.name, copy?.name)
    }

    func testDelete() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        let dataManager = DataManager()
        let container = try! NSPersistentContainer.test()

        // prepare
        dataManager.persistentContainer = container
        let item = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!

        // test
        dataManager.delete(item, context: dataManager.mainContext)
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, success: { results in
            XCTAssertEqual(results?.count, 0)
            exp.fulfill()
        })
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testFetch() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        let dataManager = DataManager()
        let container = try! NSPersistentContainer.test()

        // prepare
        dataManager.persistentContainer = container
        _ = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!

        // test
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, success: { results in
            XCTAssertEqual(results?.count, 1)
            exp.fulfill()
        })
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testSave() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        let dataManager = DataManager()
        let container = try! NSPersistentContainer.test()

        // prepare
        dataManager.persistentContainer = container
        _ = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!

        // test
        dataManager.save(context: dataManager.mainContext, success: {
            exp.fulfill()
        })
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
