import AsyncAwait
@testable import EasyLife
import Foundation
import TestExtensions
import XCTest

final class FocusTests: XCTestCase {
    private var navigationController: UINavigationController!
    private var viewController: FocusViewController!
    private var env: AppTestEnvironment!

    override func setUp() {
        super.setUp()
        navigationController = UIStoryboard.plan.instantiateInitialViewController() as? UINavigationController
        viewController = UIStoryboard.focus
          .instantiateViewController(withIdentifier: "FocusViewController") as? FocusViewController
        viewController.prepareView()
        navigationController.pushViewController(viewController, animated: false)
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

    func test_WHAT_whenX_expectY() {
        XCTFail("todo")
    }
}
