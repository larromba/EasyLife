//
//  PlanViewControllerTests.swift
//  EasyLifeTests
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
import UserNotifications
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
    
    // table view hide / show
    func test1() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
       
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.isHidden)
        
        // prepare
        dataSource.sections[0] = [MockTodoItem()]
        
        //test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.isHidden)
    }
    
    // + button opens ItemDetailViewController
    func test2() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if viewController is ItemDetailViewController {
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
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
        let dataSource = PlanDataSource()
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = nav.viewControllers.first as! PlanViewController
        let delegate = MockDelegate()
        let item = MockTodoItem()
        
        // prepare
        vc.dataSource = dataSource
        delegate.exp = exp
        delegate.item = item
        dataSource.sections[0] = [item]
        nav.delegate = delegate
        _ = vc.view
        UIApplication.shared.keyWindow!.rootViewController = nav
        
        // test
        vc.dataSorceDidLoad(dataSource)
        vc.tableView.delegate!.tableView!(vc.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
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
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
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
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        vc.dataSource = dataSource
        vc.viewWillAppear(false)
        dataSource.didLoad = false
        
        // test
        NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: nil)
        XCTAssertTrue(dataSource.didLoad)
    }
    
    // cell text color, header, actions, etc
    func test6() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
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
        missedItem.date = NSDate()
        nowItem.name = "now"
        nowItem.date = NSDate()
        laterItem.name = "later"
        laterItem.repeatState = .biweekly
        laterItem.date = NSDate()
        vc.dataSource = dataSource
        dataSource.sections = sections
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        
        // cells
        let cellMissed = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! PlanCell
        XCTAssertEqual(cellMissed.titleLabel.text, "missed")
        XCTAssertEqual(cellMissed.titleLabel.textColor, UIColor.lightRed)
        XCTAssertTrue(cellMissed.iconImageView.isHidden)
        XCTAssertEqual(cellMissed.iconImageType, .none)
        
        let cellNow = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! PlanCell
        XCTAssertEqual(cellNow.titleLabel.text, "now")
        XCTAssertEqual(cellNow.titleLabel.textColor, UIColor.black)
        XCTAssertTrue(cellNow.iconImageView.isHidden)
        XCTAssertEqual(cellMissed.iconImageType, .none)
        
        let cellNowNoName = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 1)) as! PlanCell
        XCTAssertEqual(cellNowNoName.titleLabel.text, "[no name]")
        XCTAssertEqual(cellNowNoName.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertFalse(cellNowNoName.iconImageView.isHidden)
        XCTAssertEqual(cellNowNoName.iconImageType, .noDate)
        
        let cellLater = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 2)) as! PlanCell
        XCTAssertEqual(cellLater.titleLabel.text, "later")
        XCTAssertEqual(cellLater.titleLabel.textColor, UIColor.appleGrey)
        XCTAssertFalse(cellLater.iconImageView.isHidden)
        XCTAssertEqual(cellLater.iconImageType, .recurring)
        
        // header
        let title1 = vc.tableView(vc.tableView, titleForHeaderInSection: 0)
        XCTAssertEqual(title1, "Missed...")
        
        let title2 = vc.tableView(vc.tableView, titleForHeaderInSection: 1)
        XCTAssertEqual(title2, "Today")
        
        let title3 = vc.tableView(vc.tableView, titleForHeaderInSection: 2)
        XCTAssertEqual(title3, "Later...")
        
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
    
    // table header hide / show
    func test7() {
        // mocks
        let dataSource = PlanDataSource()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        vc.dataSource = dataSource
        dataSource.delegate = vc
        dataSource.sections[2] = [MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.tableHeaderView!.isHidden)
        
        // prepare
        dataSource.sections[0] = [MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.tableHeaderView!.isHidden)
    }
    
    // badge number
    func test8() {
        // mocks
        class MockBadge: Badge {
            var _number: Int = 0
            override var number: Int {
                get {
                    return _number
                }
                set {
                    _number = newValue
                }
            }
        }
        let dataSource = PlanDataSource()
        let badge = MockBadge()
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        vc.badge = badge
        vc.dataSource = dataSource
        dataSource.delegate = vc
        dataSource.sections[0] = [MockTodoItem()]
        dataSource.sections[1] = [MockTodoItem()]
        dataSource.sections[2] = [MockTodoItem(), MockTodoItem(), MockTodoItem()]
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertEqual(badge.number, 2)
    }
    
    // folder button opens archive view
    func test9() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        UIApplication.shared.sendAction(vc.archiveButton.action!, to: vc.archiveButton.target!, from: nil, for: nil)
        let navController = vc.presentedViewController as! UINavigationController
        let rootViewController = navController.viewControllers.first!
        XCTAssertTrue(rootViewController is ArchiveViewController)
    }
    
    // projects button opens projects view
    func test10() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "PlanViewController") as! PlanViewController
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        UIApplication.shared.sendAction(vc.projectsButton.action!, to: vc.projectsButton.target!, from: nil, for: nil)
        let navController = vc.presentedViewController as! UINavigationController
        let rootViewController = navController.viewControllers.first!
        XCTAssertTrue(rootViewController is ProjectsViewController)
    }
}
