//
//  ArchiveDataSourceTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 07/06/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class ArchiveDataSourceTests: XCTestCase {
    func testItemsAppearInCorrectSection() {
        // mocks
        let exp = expectation(description: "dataSourceDidLoad(...)")
        class MockDelegate: TableDataSourceDelegate {
            var expected: [Character: [TodoItem]]!
            var exp: XCTestExpectation!
            func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
                let dataSource = dataSource as! ArchiveDataSource
                XCTAssertEqual(dataSource.data.count, expected.count)
                expected.keys.forEach { (key: Character) in
                    XCTAssertEqual(expected[key]!, dataSource.data[key]!)
                }
                exp.fulfill()
            }
        }
        let container = try! NSPersistentContainer.test()
        _ = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem // shouldnt appear in data fetch
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item4 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = ArchiveDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()

        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        item1.name = "alphazero"
        item1.done = true
        item2.name = "ape"
        item2.done = true
        item3.name = "zebra"
        item3.done = true
        item4.done = true
        delegate.expected = [
            "-": [item4],
            "A": [item1, item2],
            "Z": [item3]
        ]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    func testUndo() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(context: NSManagedObjectContext, success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ArchiveDataSource()
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let data = [
            Character("A"): [item],
        ]
        
        // prepare
        item.done = true
        dataSource.dataManager = dataManager
        dataSource.data = data
        
        // test
        dataSource.undo(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didSave)
        XCTAssertFalse(item.done)
        XCTAssertNil(item.date)
        XCTAssertEqual(item.repeatState, RepeatState.none)
    }

    func testClear() {
        // mocks
        class MockDataManager: DataManager {
            var didDelete = false
            override func delete<T>(_ entity: T, context: NSManagedObjectContext) where T : NSManagedObject {
                didDelete = true
            }
        }
        let dataSource = ArchiveDataSource()
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let data = [
            Character("A"): [item],
            ]

        // prepare
        item.done = true
        dataSource.dataManager = dataManager
        dataSource.data = data

        // test
        dataSource.clearAll()
        XCTAssertTrue(dataManager.didDelete)
    }
}
