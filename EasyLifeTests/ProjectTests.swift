@testable import EasyLife
import TestExtensions
import XCTest
import UIKit

final class ProjectTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: ProjectsViewController!
    private var alertController: AlertController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController() // TODO: from story?
        viewController = UIStoryboard.project
            .instantiateViewController(withIdentifier: "ProjectsViewController") as? ProjectsViewController
        viewController.prepareView()
        navigationController.pushViewController(viewController, animated: false)
        alertController = AlertController(presenter: viewController)
        env = AppTestEnvironment(navigationController: navigationController)
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        env = nil
        viewController = nil
        navigationController = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }
}
