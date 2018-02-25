//
//  ArchiveViewControllerTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 07/06/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
import UserNotifications
@testable import EasyLife

class ArchiveViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }
    
    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }
    
    func testTableViewHideShowAndSearchBarState() {
        // mocks
        let dataSource = ArchiveDataSource()
        let vc = UIStoryboard.archive.instantiateViewController(withIdentifier: "ArchiveViewController") as! ArchiveViewController
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.isHidden)
        XCTAssertFalse(vc.searchBar.isUserInteractionEnabled)
        
        // prepare
        dataSource.data = [Character("a"): [MockTodoItem()]]
        
        //test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.isHidden)
        XCTAssertTrue(vc.searchBar.isUserInteractionEnabled)
    }
    
    func testDoneButtonClosesView() {
        // mocks
        let exp = expectation(description: "wait")
        let vc = UIStoryboard.archive.instantiateViewController(withIdentifier: "ArchiveViewController") as! ArchiveViewController
        let baseVc = UIViewController()
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = baseVc
        baseVc.present(vc, animated: false, completion: nil)
        
        // test
        UIApplication.shared.sendAction(vc.doneButton.action!, to: vc.doneButton.target!, from: nil, for: nil)
        performAfterDelay(0.5) { () -> Void in
            XCTAssertNil(baseVc.presentedViewController)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testClearButtonDisplaysMessageAndDeletes() {
        // mocks
        let vc = UIStoryboard.archive.instantiateViewController(withIdentifier: "ArchiveViewController") as! ArchiveViewController
        let dataSource = ArchiveDataSource()

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        dataSource.data = [Character("c") : [MockTodoItem()]]

        // test
        UIApplication.shared.sendAction(vc.clearButton.action!, to: vc.clearButton.target!, from: nil, for: nil)
        XCTAssert(vc.presentedViewController is UIAlertController)
        // TODO: tap the action?
    }
    
    func testCellUI() {
        // mocks
        let dataSource = ArchiveDataSource()
        let vc = UIStoryboard.archive.instantiateViewController(withIdentifier: "ArchiveViewController") as! ArchiveViewController
        let item1 = MockTodoItem()
        let item2 = MockTodoItem()
        let item3 = MockTodoItem()
        let data = [
            Character("-"): [item1],
            Character("A"): [item2, item3],
        ]
        
        // prepare
        item1.name = nil
        item2.name = "item2"
        item3.name = "item3"
        dataSource.data = data
        vc.dataSource = dataSource
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        
        // cells
        let cell1 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! ArchiveCell
        XCTAssertEqual(cell1.titleLabel.text, "[no name]".localized)
        XCTAssertEqual(cell1.titleLabel.textColor, UIColor.appleGrey)
        
        let cell2 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! ArchiveCell
        XCTAssertEqual(cell2.titleLabel.text, "item2")
        XCTAssertEqual(cell2.titleLabel.textColor, UIColor.black)

        let cell3 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 1)) as! ArchiveCell
        XCTAssertEqual(cell3.titleLabel.text, "item3")
        XCTAssertEqual(cell3.titleLabel.textColor, UIColor.black)
        
        // header
        let title1 = vc.tableView(vc.tableView, titleForHeaderInSection: 0)
        XCTAssertEqual(title1, "-")

        let title2 = vc.tableView(vc.tableView, titleForHeaderInSection: 1)
        XCTAssertEqual(title2, "A")

        // edit actions
        let actions1 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(actions1?.count, 1)
        XCTAssertEqual(actions1?[0].title, "Undo")
        
        let actions2 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(actions2?.count, 1)
        XCTAssertEqual(actions2?[0].title, "Undo")
        
        let actions3 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 1, section: 1))
        XCTAssertEqual(actions3?.count, 1)
        XCTAssertEqual(actions3?[0].title, "Undo")
    }
    
    func testSearch() {
        // mocks
        let dataSource = ArchiveDataSource()
        let vc = UIStoryboard.archive.instantiateViewController(withIdentifier: "ArchiveViewController") as! ArchiveViewController
        let item1 = MockTodoItem()
        let item2 = MockTodoItem()
        let item3 = MockTodoItem()
        let data = [
            Character("a"): [item1, item2],
            Character("b"): [item3]
        ]
        
        // prepare
        item1.name = "ziggy"
        item2.name = "ziggy2"
        item3.name = "blah"
        dataSource.data = data
        dataSource.delegate = vc
        vc.dataSource = dataSource
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertEqual(dataSource.totalItems, 3)
        XCTAssertEqual(vc.thingsDoneLabel.text, "3 done")
        XCTAssertFalse(vc.tableView.isHidden)
        
        vc.searchBarTextDidBeginEditing(vc.searchBar)
        vc.searchBar(vc.searchBar, textDidChange: "zig")
        XCTAssertEqual(dataSource.totalItems, 2)
        XCTAssertEqual(vc.thingsDoneLabel.text, "2 done")
        XCTAssertFalse(vc.tableView.isHidden)
        
        vc.searchBar(vc.searchBar, textDidChange: "")
        XCTAssertEqual(dataSource.totalItems, 3)
        XCTAssertEqual(vc.thingsDoneLabel.text, "3 done")
        XCTAssertFalse(vc.tableView.isHidden)
        
        vc.searchBar(vc.searchBar, textDidChange: "bl")
        XCTAssertEqual(dataSource.totalItems, 1)
        XCTAssertEqual(vc.thingsDoneLabel.text, "1 done")
        XCTAssertFalse(vc.tableView.isHidden)
        
        vc.searchBar(vc.searchBar, textDidChange: "askdjhasjkdh")
        XCTAssertEqual(dataSource.totalItems, 0)
        XCTAssertEqual(vc.thingsDoneLabel.text, "0 done")
        XCTAssertTrue(vc.tableView.isHidden)
    }
}
