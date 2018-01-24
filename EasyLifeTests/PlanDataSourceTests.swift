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
        XCTAssertGreaterThan(dataSource.sections[0][1].date!, date)
        XCTAssertGreaterThan(dataSource.sections[0][1].date!, Date())
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
        XCTAssertGreaterThan(dataSource.sections[0][1].date!, date)
        XCTAssertGreaterThan(dataSource.sections[0][1].date!, Date())
    }
    
    // missed section ordering
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
                    XCTAssertEqual(dataSource.sections.count, dataSource.sections[0].count)
                    for item in expectedOrder {
                        XCTAssertEqual(item, dataSource.sections[0][expectedOrder.index(of: item)!])
                    }
                    exp.fulfill()
                }
            }
        }
        let container = try! NSPersistentContainer.test()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = PlanDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        let project1 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let project2 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!.earliest
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        project1.priority = 0
        project2.priority = 1
        item1.project = project1
        item1.date = date
        item2.project = project2
        item2.date = date
        item3.date = date
        delegate.expectedOrder = [item1, item2, item3]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // today section ordering
    func test6() {
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
                    XCTAssertEqual(dataSource.sections.count, dataSource.sections[1].count)
                    for item in expectedOrder {
                        XCTAssertEqual(item, dataSource.sections[1][expectedOrder.index(of: item)!])
                    }
                    exp.fulfill()
                }
            }
        }
        let container = try! NSPersistentContainer.test()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = PlanDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        let project1 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let project2 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let today = Date()
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        project1.priority = 0
        project2.priority = 1
        item1.project = project1
        item1.date = today
        item2.project = project2
        item2.date = today
        item3.date = today
        delegate.expectedOrder = [item1, item2, item3]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // later section ordering
    func test7() {
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
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "TodoItem", into: container.viewContext) as! TodoItem
        let dataSource = MockDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()
        
        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        dataSource._today = date
        item1.date = date.addingTimeInterval(60*60*24)
        item2.date = nil
        item3.date = date.addingTimeInterval(2*60*60*24)
        delegate.expectedOrder = [item2, item1, item3]
        delegate.exp = exp
        
        // test
        dataSource.load()
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
