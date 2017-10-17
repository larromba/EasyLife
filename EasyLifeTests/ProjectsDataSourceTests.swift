//
//  ProjectsDataSourceTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 02/09/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class ProjectsDataSourceTests: XCTestCase {
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
            var expected: [[Project]]!
            var exp: XCTestExpectation!
            var loadCount = 0
            func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
                loadCount += 1
                if loadCount == 2 {
                    let dataSource = dataSource as! ProjectsDataSource
                    XCTAssertEqual(dataSource.sections.count, expected.count)
                    for (index, items) in expected.enumerated() {
                        XCTAssertEqual(items.count, expected[index].count)
                    }
                    exp.fulfill()
                }
            }
        }
        let container = try! NSPersistentContainer.test()
        let item1 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let item2 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let item3 = NSEntityDescription.insertNewObject(forEntityName: "Project", into: container.viewContext) as! Project
        let dataSource = ProjectsDataSource()
        let dataManager = DataManager()
        let delegate = MockDelegate()

        // prepare
        dataManager.persistentContainer = container
        dataSource.dataManager = dataManager
        dataSource.delegate = delegate
        item1.priority = 0
        item2.priority = 1
        item3.priority = -1
        delegate.expected = [
            [item1, item2],
            [item3]
        ]
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
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        let sections = [
            [MockProject()],
            [],
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
    
    // can prioritise an item
    func test3() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        let project = MockProject()
        let sections = [
            [],
            [project, MockProject()],
        ]
        
        // prepare
        project.priority = -1
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.prioritize(at: IndexPath(row: 0, section: 1))
        XCTAssertEqual(project.priority, 0)
        XCTAssertTrue(dataManager.didSave)
    }
    
    // can deprioritise an item
    func test4() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        let project = MockProject()
        let sections = [
            [project, MockProject()],
            [],
        ]
        
        // prepare
        project.priority = 0
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.deprioritize(at: IndexPath(row: 0, section: 0))
        XCTAssertEqual(project.priority, -1)
        XCTAssertTrue(dataManager.didSave)
    }
    
    // move
    func test5() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        let project1 = MockProject()
        let project2 = MockProject()
        let project3 = MockProject()
        let sections = [
            [project1, project2, project3],
            [],
        ]
        
        // prepare
        project1.priority = 0
        project2.priority = 1
        project3.priority = 2
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.move(fromPath: IndexPath(row: 2, section: 0), toPath: IndexPath(row: 0, section: 0))
        XCTAssertEqual(dataSource.sections[0][0], project3)
        XCTAssertEqual(dataSource.sections[0][1], project1)
        XCTAssertEqual(dataSource.sections[0][2], project2)
        XCTAssertTrue(dataManager.didSave)
    }
    
    // can get the name of an item
    func test6() {
        // mocks
        let dataManager = DataManager()
        let dataSource = ProjectsDataSource()
        let project = MockProject()
        let sections = [
            [],
            [project, MockProject()],
        ]
        
        // prepare
        project.name = "test"
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        XCTAssertEqual(dataSource.name(at: IndexPath(row: 0, section: 1)), "test")
    }
    
    // can update the name of an item
    func test7() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        let project = MockProject()
        let sections = [
            [],
            [project, MockProject()],
        ]
        
        // prepare
        project.name = "should update"
        dataSource.dataManager = dataManager
        dataSource.sections = sections
        
        // test
        dataSource.updateName(name: "test", at: IndexPath(row: 0, section: 1))
        XCTAssertEqual(dataSource.sections[1][0].name, "test")
        XCTAssertTrue(dataManager.didSave)
    }
    
    // can add new item
    func test8() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            var didInsert = false
            override func insert<T>(entityClass: T.Type) -> T? where T : NSManagedObject {
                didInsert = true
                return super.insert(entityClass: entityClass)
            }
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ProjectsDataSource()
        let dataManager = MockDataManager()
        
        // prepare
        dataSource.dataManager = dataManager
        
        // test
        dataSource.addProject(name: "test")
        XCTAssertTrue(dataManager.didInsert)
        XCTAssertTrue(dataManager.didSave)
    }
}
