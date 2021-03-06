import AsyncAwait
import Logging
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var app: Appable?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.shortcutItems = ShortcutItem.display.map { $0.item }

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
            self.app = try await(AppFactory.make(window: window, navigationController: navigationController,
                                                 planViewController: planViewController))
            onMain { self.app?.start() }
        }, onError: { error in
            assertionFailure(error.localizedDescription)
        })
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        app?.applicationWillTerminate()
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        app?.processShortcutItem(shortcutItem)
    }
}
