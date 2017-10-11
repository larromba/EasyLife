//
//  PlanDataSourceTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class PlanDataSourceTests: XCTestCase {
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
            var missedItem: TodoItem!
            var todayItem: TodoItem!
            var laterItem: TodoItem!
            var exp: XCTestExpectation!
            var loadCount = 0
            func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
                loadCount += 1
                if loadCount == 3 {
                    let dataSource = dataSource as! PlanDataSource
                    XCTAssertEqual(dataSource.sections[0].first, missedItem)
                    XCTAssertEqual(dataSource.sections[1].first, todayItem)
                    XCTAssertEqual(dataSource.sections[2].first, laterItem)
                    exp.fulfill()
                }
            }
        }
        class MockDataSource: PlanDataSource {
            var _today: Date!
            override var today: Date {
                return _today
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!.earliest
        let container = try! NSPersistentContainer.test()
        let missedItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let todayItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let laterItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = MockDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        dataSource._today = date
        missedItem.date = date.addingTimeInterval(-1)
        todayItem.date = date as Date!
        laterItem.date = date.addingTimeInterval(60*60*24)
        delegate.missedItem = missedItem
        delegate.todayItem = todayItem
        delegate.laterItem = laterItem
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // delete deletes
    func test2() {
        // mocks
        class MockDataManager: DataManager {
            var didDelete = false
            override func delete<T : NSManagedObject>(_ entity: T) {
                didDelete = true
            }
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = PlanDataSource()
        let dataManager = MockDataManager()
        let sections = [
            [MockTodoItem()],
            [],
            []
        ]
        
        // prepare
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.delete(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didDelete)
        XCTAssertTrue(dataManager.didSave)
        XCTAssertNil(dataSource.sections[0].first)
    }
    
    // done marks as done / or increments
    func test3() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = PlanDataSource()
        let dataManager = MockDataManager()
        let item1 = MockTodoItem()
        let item2 = MockTodoItem()
        let sections = [
            [item1, item2],
            [],
            []
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!
    
        // prepare
        item2.date = date as Date?
        item2.repeatState = .daily
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.done(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didSave)
        XCTAssertTrue(dataSource.sections[0][0].done)
        
        dataSource.done(at: IndexPath(row: 1, section: 0))
        XCTAssertFalse(dataSource.sections[0][1].done)
        XCTAssertEqual(dataSource.sections[0][1].date, dateFormatter.date(from: "22/04/2017")! as Date)
    }
    
    // later nils date / or increments
    func test4() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = PlanDataSource()
        let dataManager = MockDataManager()
        let item1 = MockTodoItem()
        let item2 = MockTodoItem()
        let sections = [
            [item1, item2],
            [],
            []
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!
        
        // prepare
        item1.date = date as Date?
        item2.date = date as Date?
        item2.repeatState = .daily
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.later(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didSave)
        XCTAssertNil(dataSource.sections[0][0].date)
        
        dataSource.later(at: IndexPath(row: 1, section: 0))
        XCTAssertEqual(dataSource.sections[0][1].date, dateFormatter.date(from: "22/04/2017")! as Date)
    }
    
    // later section ordering
    func test5() {
        // mocks
        let exp = expectation(description: "dataSourceDidLoad(...)")
        class MockDelegate: TableDataSourceDelegate {
            var expectedOrder: [TodoItem]!
            var exp: XCTestExpectation!
            var loadCount = 0
            func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
                loadCount += 1
                if loadCount == 3 {
                    let dataSource = dataSource as! PlanDataSource
                    XCTAssertEqual(dataSource.sections.count, dataSource.sections[2].count)
                    for item in expectedOrder {
                        XCTAssertEqual(item, dataSource.sections[2][expectedOrder.index(of: item)!])
                    }
                    exp.fulfill()
                }
            }
        }
        class MockDataSource: PlanDataSource {
            var _today: Date!
            override var today: Date {
                return _today
            }
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!.earliest
        let container = try! NSPersistentContainer.test()
        let laterItem1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let laterItem2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let laterItem3 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = MockDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        dataSource._today = date
        laterItem1.date = date.addingTimeInterval(60*60*24)
        laterItem2.date = nil
        laterItem3.date = date.addingTimeInterval(2*60*60*24)
        delegate.expectedOrder = [laterItem2, laterItem1, laterItem3]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
