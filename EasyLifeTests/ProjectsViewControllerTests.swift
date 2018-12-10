import XCTest
import CoreData
import UserNotifications
@testable import EasyLife

class ProjectsViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        super.tearDown()
        UIView.setAnimationsEnabled(true)
    }

    func testTableViewHideShowAndEditButtonState() {
        // mocks
        let dataSource = ProjectsDataSource()
        let vc = UIStoryboard.project.instantiateViewController(withIdentifier: "ProjectsViewController") as! ProjectsViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertTrue(vc.tableView.isHidden)
        XCTAssertFalse(vc.editButton.isEnabled)

        // prepare
        dataSource.sections = [[MockProject()]]

        //test
        vc.dataSorceDidLoad(dataSource)
        XCTAssertFalse(vc.tableView.isHidden)
        XCTAssertTrue(vc.editButton.isEnabled)
    }

    func testDoneButtonClosesView() {
        // mocks
        let exp = expectation(description: "wait")
        let vc = UIStoryboard.project.instantiateViewController(withIdentifier: "ProjectsViewController") as! ProjectsViewController
        let baseVc = UIViewController()

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = baseVc
        baseVc.present(vc, animated: false, completion: nil)

        // test
        UIApplication.shared.sendAction(vc.doneButton.action!, to: vc.doneButton.target!, from: nil, for: nil)

        // tests
        performAfterDelay(0.5) { () -> Void in
            XCTAssertNil(baseVc.presentedViewController)
            exp.fulfill()
        }
        waitForExpectations(timeout: 1.0) { (err: Error?) in
            XCTAssertNil(err)
        }
    }

    func testCellUI() {
        // mocks
        let dataSource = ProjectsDataSource()
        let vc = UIStoryboard.project.instantiateViewController(withIdentifier: "ProjectsViewController") as! ProjectsViewController
        let item1 = MockProject()
        let item2 = MockProject()
        let item3 = MockProject()
        let sections = [
            [item1, item2],
            [item3]
        ]

        // prepare
        item1.name = "item1"
        item2.name = "item2"
        item3.name = "item3"
        item1.priority = 0
        item2.priority = 1
        item3.priority = -1
        dataSource.sections = sections
        vc.dataSource = dataSource
        UIApplication.shared.keyWindow!.rootViewController = vc

        // test
        vc.dataSorceDidLoad(dataSource)

        // cells
        let cell1 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as! ProjectCell
        XCTAssertEqual(cell1.titleLabel.text, "item1")
        XCTAssertEqual(cell1.titleLabel.textColor, .black)
        XCTAssertEqual(cell1.tagView.isHidden, false)
        XCTAssertEqual(cell1.tagView.cornerColor, .priority1)

        let cell2 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 1, section: 0)) as! ProjectCell
        XCTAssertEqual(cell2.titleLabel.text, "item2")
        XCTAssertEqual(cell2.titleLabel.textColor, .black)
        XCTAssertEqual(cell2.tagView.isHidden, false)
        XCTAssertEqual(cell2.tagView.cornerColor, .priority2)

        let cell3 = vc.tableView(vc.tableView, cellForRowAt: IndexPath(row: 0, section: 1)) as! ProjectCell
        XCTAssertEqual(cell3.titleLabel.text, "item3")
        XCTAssertEqual(cell3.titleLabel.textColor, .appleGrey)
        XCTAssertEqual(cell3.tagView.isHidden, true)

        // header
        let title1 = vc.tableView(vc.tableView, titleForHeaderInSection: 0)
        XCTAssertEqual(title1, "Prioritized")

        let title2 = vc.tableView(vc.tableView, titleForHeaderInSection: 1)
        XCTAssertEqual(title2, "Deprioritized")

        // edit actions
        let actions1 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(actions1?.count, 2)
        XCTAssertEqual(actions1?[1].title, "Deprioritize")
        XCTAssertEqual(actions1?[0].title, "Delete")

        let actions2 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(actions2?.count, 2)
        XCTAssertEqual(actions2?[1].title, "Deprioritize")
        XCTAssertEqual(actions2?[0].title, "Delete")

        var actions3 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(actions3?.count, 2)
        XCTAssertEqual(actions3?[1].title, "Prioritize")
        XCTAssertEqual(actions3?[0].title, "Delete")
        XCTAssertEqual(actions3?[0].title, "Delete")

        ////////////////////////////////////////////////

        // mocks
        let item4 = MockProject()
        let item5 = MockProject()
        let item6 = MockProject()

        // prepare
        item4.name = "item4"
        item5.name = "item5"
        item6.name = "item6"
        item4.priority = 2
        item5.priority = 3
        item6.priority = 4
        dataSource.sections = [
            [item1, item2, item4, item5, item6],
            [item3]
        ]

        // test
        vc.dataSorceDidLoad(dataSource)

        // edit actions
        actions3 = vc.tableView(vc.tableView, editActionsForRowAt: IndexPath(row: 0, section: 1))
        XCTAssertEqual(actions3?.count, 1)
        XCTAssertEqual(actions3?[0].title, "Delete")
    }

    func testEditButtonTogglesEditMode() {
        // mocks
        let vc = UIStoryboard.project.instantiateViewController(withIdentifier: "ProjectsViewController") as! ProjectsViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        //test
        UIApplication.shared.sendAction(vc.editButton.action!, to: vc.editButton.target!, from: nil, for: nil)
        XCTAssertTrue(vc.tableView.isEditing)

        UIApplication.shared.sendAction(vc.editButton.action!, to: vc.editButton.target!, from: nil, for: nil)
        XCTAssertFalse(vc.tableView.isEditing)
    }

    func testProjectButtonShowsAlertControllerWithTextField() {
        // mocks
        let vc = UIStoryboard.project.instantiateViewController(withIdentifier: "ProjectsViewController") as! ProjectsViewController

        // prepare
        UIApplication.shared.keyWindow!.rootViewController = vc

        //test
        UIApplication.shared.sendAction(vc.addButton.action!, to: vc.addButton.target!, from: nil, for: nil)
        XCTAssertTrue(vc.presentedViewController is UIAlertController)
        XCTAssertEqual((vc.presentedViewController as? UIAlertController)?.textFields?.count ?? 0, 1)

        let alertController = (vc.presentedViewController as! UIAlertController)
        let action = alertController.actions[1]
        let textField = alertController.textFields!.first!
        textField.text = "test"
        vc.textFieldDidChange(textField)
        XCTAssertTrue(action.isEnabled)
        textField.text = ""
        vc.textFieldDidChange(textField)
        XCTAssertFalse(action.isEnabled)
    }
}
