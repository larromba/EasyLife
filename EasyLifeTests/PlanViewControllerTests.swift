//
//  PlanViewControllerTests.swift
//  EasyLifeTests
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class PlanViewControllerTests: XCTestCase {
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
    
    // no data, hide table view
    func test1() {
        // mocks
        class MockDataManager: DataManager {
            override func fetch<T : NSManagedObject>(entityClass: T.Type, sortBy: String?, isAscending: Bool, predicate: NSPredicate?, success: @escaping DataManager.FetchSuccess, failure: DataManager.Failure?) {
                success([])
            }
        }
        let dataManager = MockDataManager()
        let tableView = UITableView()
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        vc.tableView = tableView
        vc.dataSource = dataSource
        dataSource.dataManager = dataManager
        dataSource.delegate = vc

        // test
        dataSource.load()
        XCTAssertTrue(tableView.isHidden)
    }
    
    // + button opens ItemDetailViewController
    func test2() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if let _ = viewController as? ItemDetailViewController {
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.main.instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! PlanViewController
        let delegate = MockDelegate()
        
        // prepare
        delegate.exp = exp
        nav.delegate = delegate
        UIApplication.shared.keyWindow!.rootViewController = nav
        
        // test
        UIApplication.shared.sendAction(vc.addButton.action!, to: vc.addButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // tapping cell opens ItemDetailViewController
    func test3() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            var item: MockTodoItem!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if let viewController = viewController as? ItemDetailViewController, viewController.item == item {
                    exp.fulfill()
                }
            }
        }
        class MockDataManager: DataManager {
            var item: MockTodoItem!
            override func fetch<T : NSManagedObject>(entityClass: T.Type, sortBy: String?, isAscending: Bool, predicate: NSPredicate?, success: @escaping DataManager.FetchSuccess, failure: DataManager.Failure?) {
                success([item])
            }
        }
        let dataManager = MockDataManager()
        let tableView = UITableView()
        let dataSource = PlanDataSource()
        let nav = UIStoryboard.main.instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! PlanViewController
        let delegate = MockDelegate()
        let item = MockTodoItem()
        
        // prepare
        vc.tableView = tableView
        vc.dataSource = dataSource
        dataSource.dataManager = dataManager
        dataSource.delegate = vc
        delegate.exp = exp
        delegate.item = item
        dataManager.item = item
        tableView.delegate = vc
        nav.delegate = delegate
        UIApplication.shared.keyWindow!.rootViewController = nav
        
        // test
        dataSource.load()
        tableView.delegate!.tableView!(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // load called on viewWillAppear
    func test4() {
        // mocks
        class MockPlanDataSource: PlanDataSource {
            var didLoad = false
            override func load() {
                didLoad = true
            }
        }
        let dataSource = MockPlanDataSource()
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        vc.dataSource = dataSource
        
        // test
        vc.viewWillAppear(false)
        XCTAssertTrue(dataSource.didLoad)
    }
    
    // load called on UIApplicationWillEnterForeground notification
    func test5() {
        // mocks
        class MockPlanDataSource: PlanDataSource {
            var didLoad = false
            override func load() {
                didLoad = true
            }
        }
        let dataSource = MockPlanDataSource()
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        vc.dataSource = dataSource
        vc.viewWillAppear(false)
        dataSource.didLoad = false
        
        // test
        NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: nil)
        XCTAssertTrue(dataSource.didLoad)
    }
    
    // cell text color and actions
    func test6() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.main.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        let missedItem = MockTodoItem()
        let nowItem = MockTodoItem()
        let nowItemNoName = MockTodoItem()
        let laterItem = MockTodoItem()
        let sections = [
            [missedItem],
            [nowItem, nowItemNoName],
            [laterItem]
        ]
        
        // prepare
        missedItem.name = "missed"
        nowItem.name = "now"
        laterItem.name = "later"
        vc.dataSource = dataSource
        dataSource.sections = sections
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        
        // cells
        let cellMissed = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! PlanCell
        XCTAssertEqual(cellMissed.titleLabel.text, "missed")
        XCTAssertEqual(cellMissed.titleLabel.textColor, UIColor.lightRed)
        
        let cellNow = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! PlanCell
        XCTAssertEqual(cellNow.titleLabel.text, "now")
        XCTAssertEqual(cellNow.titleLabel.textColor, UIColor.black)
        
        let cellNowNoName = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 1)) as! PlanCell
        XCTAssertEqual(cellNowNoName.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertEqual(cellNowNoName.titleLabel.text, "[no name]")

        let cellLater = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 2)) as! PlanCell
        XCTAssertEqual(cellLater.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertEqual(cellLater.titleLabel.text, "later")
        
        // edit actions
        let missedActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(missedActions?.count, 2)
        XCTAssertEqual(missedActions?[1].title, "Delete")
        XCTAssertEqual(missedActions?[0].title, "Done")
        
        let todayActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(todayActions?.count, 3)
        XCTAssertEqual(todayActions?[2].title, "Later")
        XCTAssertEqual(todayActions?[1].title, "Delete")
        XCTAssertEqual(todayActions?[0].title, "Done")
        
        let laterActions = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 2))
        XCTAssertEqual(laterActions?.count, 2)
        XCTAssertEqual(laterActions?[1].title, "Delete")
        XCTAssertEqual(laterActions?[0].title, "Done")
    }
}
