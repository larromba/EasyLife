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
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // items appear in correct section
    func test1() {
        // mocks
        let exp = expectation(description: "dataSourceDidLoad(...)")
        class MockDelegate: TableDataSourceDelegate {
            var expected: [Date: [TodoItem]]!
            var exp: XCTestExpectation!
            func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
                let dataSource = dataSource as! ArchiveDataSource
                XCTAssertEqual(dataSource.data.count, expected.count)
                expected.keys.forEach { (date: Date) in
                    XCTAssertEqual(expected[date]!, dataSource.data[date]!)
                }
                exp.fulfill()
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let container = try! NSPersistentContainer.test()
        _ = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem // shouldnt appear in data fetch
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = ArchiveDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        let date1 = dateFormatter.date(from: "21/04/2017")!.earliest
        let date2 = date1.addingTimeInterval(60*60*24)
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        item1.date = date1
        item1.done = true
        item2.date = date2
        item2.done = true
        delegate.expected = [
            date1: [item1],
            date2: [item2]
        ]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // undo undoes
    func test2() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ArchiveDataSource()
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let data = [
            Date(): [item],
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
}
