import Logging
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var appController: AppControlling?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            log("app is in test mode")
            return true
        }
        #endif
        log("open \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? "nil")\n")

        guard
            let window = window,
            let navigationController = window.rootViewController as? UINavigationController,
            let planViewController = navigationController.viewControllers.first as? PlanViewController else {
                fatalError("expected UIWindow, UINavigationController, PlanViewController")
        }
        appController = AppControllerFactory.make(window: window, navigationController: navigationController,
                                                  planViewController: planViewController)
        return true
    }
}
