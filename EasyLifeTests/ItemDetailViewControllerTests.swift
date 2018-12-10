import XCTest
import CoreData
@testable import EasyLife

class ItemDetailViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }

    func testTextFieldInputViews() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataSource = ItemDetailDataSource()

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.dataSource = dataSource

        // test
        XCTAssertEqual(vc.titleTextField.keyboardType, .default)
        XCTAssertEqual(vc.textView.keyboardType, .default)
        XCTAssertEqual(vc.repeatsTextField.inputView, vc.repeatPicker)
        XCTAssertEqual(vc.projectTextField.inputView, vc.projectPicker)

        _ = vc.dateTextField.delegate!.textFieldShouldBeginEditing!(vc.dateTextField)
        XCTAssertEqual(vc.dateTextField.inputView, vc.simpleDatePicker)

        dataSource.date = Date()
        _ = vc.dateTextField.delegate!.textFieldShouldBeginEditing!(vc.dateTextField)
        XCTAssertEqual(vc.dateTextField.inputView, vc.datePicker)
    }

    func testToolbar() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.titleTextField.becomeFirstResponder()

        // tests
        XCTAssertEqual(vc.toolbar.items?.count, 7)

        vc.dateTextField.becomeFirstResponder()
        XCTAssertEqual(vc.toolbar.items?.count, 8)
    }

    func testCalendarButtonTogglesAndChangesInputView() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.dateTextField.becomeFirstResponder()

        // tests
        let button1 = vc.toolbar.items![4]
        UIApplication.shared.sendAction(button1.action!, to: button1.target!, from: nil, for: nil)
        XCTAssertEqual(vc.dateTextField.inputView, vc.datePicker)

        let button2 = vc.toolbar.items![4]
        UIApplication.shared.sendAction(button2.action!, to: button2.target!, from: nil, for: nil)
        XCTAssertEqual(vc.dateTextField.inputView, vc.simpleDatePicker)

        XCTAssertNotEqual(button1, button2)
    }

    func testLeftRightToolbarButtonsSwitchInputViews() {
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

    func testDoneClosesInputView() {
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

    func testBlockedButtonState() {
        // mocks
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataSource = ItemDetailDataSource()

        // prepare
        vc.dataSource = dataSource
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.viewWillAppear(false)
        dataSource.blockable = [BlockedItem(item: MockTodoItem(), isBlocked: true)]

        // test
        XCTAssertTrue(vc.blockedButton!.isEnabled)

        dataSource.blockable = []
        XCTAssertFalse(vc.blockedButton!.isEnabled)
    }

    func testBlockedButton() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDelegate: NSObject, UINavigationControllerDelegate {
            var exp: XCTestExpectation!
            func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                if let viewController = viewController as? BlockedViewController {
                    XCTAssertNotNil(viewController.dataSource.data) // test passing data to BlockedViewController
                    exp.fulfill()
                }
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        nav.pushViewController(vc, animated: false)
        let dataSource = ItemDetailDataSource()
        let blockable = [BlockedItem(item: MockTodoItem(), isBlocked: true)]
        let delegate = MockDelegate()

        // prepare
        _ = vc.view
        delegate.exp = exp
        nav.delegate = delegate
        UIApplication.shared.keyWindow!.rootViewController = nav
        dataSource.blockable = blockable
        vc.dataSource = dataSource

        // test
        UIApplication.shared.sendAction(vc.blockedButton.action!, to: vc.blockedButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }

        vc.dataSource.blockable = nil
        vc.viewWillAppear(false)
        XCTAssertNotNil(vc.dataSource.blockable) // test getting data from BlockedViewController
    }

    func testSave() {
        // mocks
        class MockDataManager: DataManager {
            var saved = false
            var item: MockTodoItem!
            var projects: [Project]!
            override func save(context: NSManagedObjectContext, success: DataManager.Success?, failure: DataManager.Failure?) {
                saved = true
                success!()
            }
            override func insert<T>(entityClass: T.Type, context: NSManagedObjectContext, transient: Bool) -> T? where T: NSManagedObject {
                return item as? T
            }
        }
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let project = MockProject()
        let date = Date()
        let dataSource = ItemDetailDataSource()

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        vc.dataSource = dataSource
        vc.titleTextField.text = "title"
        vc.titleTextField.sendActions(for: .editingChanged)
        dataSource.date = date
        dataSource.projects = [project, MockProject(), MockProject()]
        vc.repeatPicker.delegate!.pickerView!(vc.repeatPicker, didSelectRow: 3, inComponent: 0)
        vc.projectPicker.delegate!.pickerView!(vc.projectPicker, didSelectRow: 0, inComponent: 0)
        vc.textView.text = "notes"
        vc.textViewDidChange(vc.textView)
        dataManager.item = item
        dataSource.dataManager = dataManager

        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        XCTAssertTrue(dataManager.saved)
        XCTAssertEqual(item.name, "title")
        XCTAssertEqual(item.date as Date?, date)
        XCTAssertEqual(item.notes, "notes")
        XCTAssertEqual(item.repeats, 3)
        XCTAssertEqual(item.project, project)
    }

    func testSavePopsViewController() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDataManager: DataManager {
            override func save(context: NSManagedObjectContext, success: DataManager.Success?, failure: DataManager.Failure?) {
                success!()
            }
            override func insert<T>(entityClass: T.Type, context: NSManagedObjectContext, transient: Bool) -> T? where T: NSManagedObject {
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
        let dataSource = ItemDetailDataSource()

        // prepare
        _ = vc.view
        nav.pushViewController(vc, animated: false)
        nav.delegate = delegate
        delegate.exp = exp
        vc.dataSource = dataSource
        dataSource.dataManager = dataManager
        vc.viewWillAppear(false)
        UIApplication.shared.keyWindow!.rootViewController = nav

        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testSaveCalledOnViewWillDissapear() {
        // mocks
        let exp = expectation(description: "navigationController.popViewController(...)")
        class MockDataManager: DataManager {
            var saved = false
            var exp: XCTestExpectation!
            override func save(context: NSManagedObjectContext, success: DataManager.Success?, failure: DataManager.Failure?) {
                saved = true
                exp.fulfill()
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let dataSource = ItemDetailDataSource()

        // prepare
        _ = vc.view
        vc.dataSource = dataSource
        dataSource.dataManager = dataManager
        dataSource.item = item
        dataManager.exp = exp
        nav.pushViewController(vc, animated: false)
        vc.viewWillAppear(false)
        UIApplication.shared.keyWindow!.rootViewController = nav

        // test
        nav.popViewController(animated: false)
        waitForExpectations(timeout: 1.0) { (_: Error?) in
            XCTAssertTrue(dataManager.saved)
        }
    }

    func testDelete() {
        // mocks
        class MockDataManager: DataManager {
            var deleted = false
            var item: MockTodoItem!
            override func delete<T>(_ entity: T, context: NSManagedObjectContext) where T: NSManagedObject {
                if item == entity {
                    deleted = true
                }
            }
        }
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let item = MockTodoItem()
        let dataSource = ItemDetailDataSource()

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc
        dataSource.item = item
        dataSource.dataManager = dataManager
        dataManager.item = item
        vc.dataSource = dataSource
        vc.viewDidLoad()
        vc.viewWillAppear(false)

        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        XCTAssertTrue(dataManager.deleted)
    }

    func testDeletePopsViewController() {
        // mocks
        let exp = expectation(description: "navigationController.willShow(...)")
        class MockDataManager: DataManager {
            override func delete<T>(_ entity: T, context: NSManagedObjectContext) where T: NSManagedObject {}
            override func save(context: NSManagedObjectContext, success: DataManager.Success?, failure: DataManager.Failure?) {
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
        let dataSource = ItemDetailDataSource()

        // prepare
        _ = vc.view
        UIApplication.shared.keyWindow!.rootViewController = nav
        vc.dataSource = dataSource
        nav.pushViewController(vc, animated: false)
        nav.delegate = delegate
        delegate.exp = exp
        dataSource.dataManager = dataManager
        dataSource.item = item
        vc.viewWillAppear(false)

        // test
        UIApplication.shared.sendAction(vc.saveButton.action!, to: vc.saveButton.target!, from: nil, for: nil)
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testUI() {
        // mocks
        class MockDataManager: DataManager {
            var projects: [MockProject]!
            override func fetch<T>(entityClass: T.Type, sortBy: [NSSortDescriptor]?, context: NSManagedObjectContext,
                                   predicate: NSPredicate?, success: @escaping DataManager.FetchSuccess,
                                   failure: DataManager.Failure?) where T: NSManagedObject {
                success(projects)
            }
        }
        let nav = UIStoryboard.plan.instantiateInitialViewController() as! UINavigationController
        let vc = UIStoryboard.plan.instantiateViewController(withIdentifier: "ItemDetailViewController") as! ItemDetailViewController
        let dataManager = MockDataManager()
        let dataSource = ItemDetailDataSource()

        // prepare
        _ = vc.view
        UIApplication.shared.keyWindow!.rootViewController = nav
        vc.dataSource = dataSource
        dataSource.dataManager = dataManager
        dataManager.projects = [MockProject()]
        vc.viewDidLoad()
        vc.viewWillAppear(false)

        // test
        XCTAssertTrue(vc.projectTextField.isUserInteractionEnabled)
        XCTAssertEqual(vc.projectTextField.alpha, 1.0)

        // prepare
        dataSource.projects = []

        // test
        XCTAssertFalse(vc.projectTextField.isUserInteractionEnabled)
        XCTAssertEqual(vc.projectTextField.alpha, 0.5)
    }
}
