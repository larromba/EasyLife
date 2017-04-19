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
        UIApplication.shared.keyWindow?.rootViewController = nav
        
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
        UIApplication.shared.keyWindow?.rootViewController = nav
        
        // test
        dataSource.load()
        tableView.delegate!.tableView!(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
