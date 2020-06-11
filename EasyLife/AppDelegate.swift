import AsyncAwait
import Logging
import UIKit

// TODO: search app & check protocols are being used (not direct references)

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var appController: AppControlling?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            log("app is in test mode")
            return true
        }
        #endif
        log("open \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? "")\n")

        guard
            let window = window,
            let navigationController = window.rootViewController as? UINavigationController,
            let planViewController = navigationController.viewControllers.first as? PlanViewControlling else {
                assertionFailure("expected UIWindow, UINavigationController, PlanViewControlling")
                return true
        }
        async({
            self.appController = try await(AppControllerFactory.make(window: window,
                                                                     navigationController: navigationController,
                                                                     planViewController: planViewController))
            onMain {
                self.appController?.start()
            }
        }, onError: { error in
            assertionFailure(error.localizedDescription)
        })
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        appController?.applicationWillTerminate()
    }
}
