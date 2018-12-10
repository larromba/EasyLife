import UIKit
import Logging

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow? {
		didSet {
			guard let window = window else {
				fatalErrorHandler = nil
				return
			}
			fatalErrorHandler = FatalErrorHandler(window: window)
		}
	}
    var dataManager: DataManager
	var fatalErrorHandler: FatalErrorHandler?

    override init() {
        dataManager = DataManager.shared
        super.init()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        log("\nDEBUG BUILD")
        log("open \(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? "nil")\n")

        dataManager.load()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        dataManager.save(context: dataManager.mainContext)
    }
}
