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
        class MockDataManager: DataManager {
            var _mainContext: NSManagedObjectContext!
            override var mainContext: NSManagedObjectContext {
                return _mainContext
            }
        }
        class MockDelegate: PlanDataSourceDelegate {
            var missedItem: TodoItem!
            var todayItem: TodoItem!
            var laterItem: TodoItem!
            var exp: XCTestExpectation!
            var loadCount = 0
            func dataSorceDidLoad(_ dataSource: PlanDataSource) {
                loadCount += 1
                if loadCount == 3 {
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
        let context = NSManagedObjectContext.test
        let missedItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: context) as! TodoItem
        let todayItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: context) as! TodoItem
        let laterItem = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: context) as! TodoItem
        let dataSource = MockDataSource()
        let dataManager = MockDataManager()
        let delegate = MockDelegate()
        
        // prepare
        dataManager._mainContext = context
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        dataSource._today = date
        missedItem.date = date.addingTimeInterval(-1) as NSDate!
        todayItem.date = date as NSDate!
        laterItem.date = date.addingTimeInterval(60*60*24) as NSDate!
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
        item2.date = date as NSDate?
        item2.repeatState = .daily
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.done(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didSave)
        XCTAssertTrue(dataSource.sections[0][0].done)
        
        dataSource.done(at: IndexPath(row: 1, section: 0))
        XCTAssertFalse(dataSource.sections[0][1].done)
        XCTAssertEqual(dataSource.sections[0][1].date as! Date, dateFormatter.date(from: "22/04/2017")!)
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
        item1.date = date as NSDate?
        item2.date = date as NSDate?
        item2.repeatState = .daily
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.later(at: IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataManager.didSave)
        XCTAssertNil(dataSource.sections[0][0].date)
        
        dataSource.later(at: IndexPath(row: 1, section: 0))
        XCTAssertEqual(dataSource.sections[0][1].date as! Date, dateFormatter.date(from: "22/04/2017")!)
    }
}
