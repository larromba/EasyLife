import CoreData
import UIKit

enum AppControllerFactory {
    static func make(window: UIWindow, navigationController: UINavigationController,
                     planViewController: PlanViewController) -> AppControlling {
        let persistentContainer = NSPersistentContainer(name: "EasyLife")
        let dataManager = CoreDataManager(persistentContainer: persistentContainer)
        let planRepository = PlanRepository(dataManager: dataManager)
        let badge = AppBadge()
        let planController = PlanController(
            viewController: planViewController,
            alertController: AlertController(presenter: planViewController),
            repository: planRepository,
            badge: badge
        )
        let archiveRepository = ArchiveRepository(dataManager: dataManager)
        let archiveController = ArchiveController(repository: archiveRepository)
        let planCoordinator = PlanCoordinator(navigationController: navigationController,
                                              planController: planController,
                                              archiveController: archiveController)
        let fatalErrorHandler = FatalErrorHandler(window: window)
        return AppController(dataManager: dataManager, planCoordinator: planCoordinator,
                             fatalErrorHandler: fatalErrorHandler)
    }
}
