//
//  ItemDetailsViewControllerTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class ItemDetailsViewControllerTests: XCTestCase {
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
    
    // textfields have correct input views
    func test1() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        XCTAssertEqual(vc.titleTextField.keyboardType, .default)
        XCTAssertEqual(vc.textView.keyboardType, .default)
        XCTAssertEqual(vc.repeatsTextField.inputView, vc.repeatPicker)
        XCTAssertEqual(vc.projectTextField.inputView, vc.projectPicker)
        
        _ = vc.dateTextField.delegate!.textFieldShouldBeginEditing!(vc.dateTextField)
        XCTAssertEqual(vc.dateTextField.inputView, vc.simpleDatePicker)
        
        vc.date = Date()
        _ = vc.dateTextField.delegate!.textFieldShouldBeginEditing!(vc.dateTextField)
        XCTAssertEqual(vc.dateTextField.inputView, vc.datePicker)
    }
    
    // left right buttons switch input views
    func test2() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let prev = vc.toolbar.items![0]
        let next = vc.toolbar.items![2]
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.titleTextField.becomeFirstResponder()
        UIApplication.shared.sendAction(prev.action!, to: prev.target!, from: nil, for: nil)
        XCTAssertFalse(vc.titleTextField.isFirstResponder)
        XCTAssertTrue(vc.textView.isFirstResponder)
        
        vc.titleTextField.becomeFirstResponder()
        UIApplication.shared.sendAction(next.action!, to: next.target!, from: nil, for: nil)
        XCTAssertFalse(vc.titleTextField.isFirstResponder)
        XCTAssertTrue(vc.dateTextField.isFirstResponder)
    }
    
    // done closes input view
    func test3() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let done = vc.toolbar.items!.last!
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        
        // test
        vc.titleTextField.becomeFirstResponder()
        UIApplication.shared.sendAction(done.action!, to: done.target!, from: nil, for: nil)
        XCTAssertFalse(vc.titleTextField.isFirstResponder)
    }
    
    // save saves all info
    func test4() {
        // mocks
        class MockDataManager: DataManager {
            var saved = false
            var item: MockTodoItem!
            var projects: [Project]!
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                saved = true
                success!()
            }
            override func insert<T : NSManagedObject>(entityClass: T.Type) -> T? {
                return item as? T
            }
        }
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let project = MockProject()
        let date = Date()
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.titleTextField.text = "title"
        vc.date = date
        vc.projects = [project, MockProject(), MockProject()]
        vc.repeatPicker.delegate!.pickerView!(vc.repeatPicker, didSelectRow: 3, inComponent: 0)
        vc.projectPicker.delegate!.pickerView!(vc.projectPicker, didSelectRow: 0, inComponent: 0)
        vc.textView.text = "notes"
        dataManager.item = item
        vc.dataManager = dataManager

        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        XCTAssertTrue(dataManager.saved)
        XCTAssertEqual(item.name, "title")
        XCTAssertEqual(item.date as Date?, date)
        XCTAssertEqual(item.notes, "notes")
        XCTAssertEqual(item.repeats, 3)
        XCTAssertEqual(item.project, project)
    }
    
    // save pops vc
    func test5() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDataManager: DataManager {
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                success!()
            }
            override func insert<T : NSManagedObject>(entityClass: T.Type) -> T? {
                return MockTodoItem() as? T
            }
        }
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if viewController is PlanViewController {
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let delegate = MockDelegate()
        let dataManager = MockDataManager()
        
        // prepare
        _ = vc.view
        nav.pushViewController(vc, animated: false)
        nav.delegate = delegate
        delegate.exp = exp
        vc.dataManager = dataManager
        UIApplication.shared.keyWindow!.rootViewController = nav
        
        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
    
    // save called on viewWillDisappear
    func test6() {
        // mocks
        class MockDataManager: DataManager {
            var saved = false
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                saved = true
            }
        }
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.dataManager = dataManager
        vc.item = item
        
        // test
        vc.viewWillDisappear(false)
        XCTAssertTrue(dataManager.saved)
    }
    
    // delete icon deletes
    func test7() {
        // mocks
        class MockDataManager: DataManager {
            var deleted = false
            var item: MockTodoItem!
            override func delete<T : NSManagedObject>(_ entity: T) {
                if item == entity {
                    deleted = true
                }
            }
        }
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        
        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.item = item
        dataManager.item = item
        vc.dataManager = dataManager
        vc.viewWillAppear(false)
        
        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        XCTAssertTrue(dataManager.deleted)
    }
    
    // delete pops vc
    func test8() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDataManager: DataManager {
            override func delete<T : NSManagedObject>(_ entity: T) {}
            override func save(success: DataManager.Success?, failure: DataManager.Failure?) {
                success?()
            }
        }
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if viewController is PlanViewController {
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let delegate = MockDelegate()
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        
        // prepare
        _ = vc.view
        UIApplication.shared.keyWindow!.rootViewController = nav
        vc.item = item
        nav.pushViewController(vc, animated: false)
        nav.delegate = delegate
        delegate.exp = exp
        vc.dataManager = dataManager
        vc.viewWillAppear(false)
        
        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }
}
