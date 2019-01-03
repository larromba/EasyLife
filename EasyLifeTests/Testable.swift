import AsyncAwait
import CoreData
import UIKit
@testable import EasyLife

final class Env: TestEnvironment {
    init(persistentContainer: NSPersistentContainer,
         planViewController: PlanViewControlling,
         badge: Badge,
         navigationController: UINavigationController,
         window: UIWindow,
         now: Date) {
        let dataManager = CoreDataManager(persistentContainer: persistentContainer)
        try! await(dataManager.load())

        let planController = PlanController(
            viewController: planViewController,
            alertController: AlertController(presenter: planViewController),
            repository: PlanRepository(dataManager: dataManager),
            badge: badge
        )
        let blockedRepository = BlockedRepository(dataManager: dataManager)
        let itemDetailRepository = ItemDetailRepository(dataManager: dataManager, now: now)
        let planCoordinator = PlanCoordinator(
            navigationController: navigationController,
            planController: planController,
            itemDetailController: ItemDetailController(repository: itemDetailRepository),
            blockedController: BlockedController(repository: blockedRepository)
        )

        let archiveRepository = ArchiveRepository(dataManager: dataManager)
        let archiveController = ArchiveController(repository: archiveRepository)
        let projectsRepository = ProjectsRepository(dataManager: dataManager)
        let projectsController = ProjectsController(repository: projectsRepository)

        let appRouter = AppRouter(
            planCoordinator: planCoordinator,
            archiveCoordinator: ArchiveCoordinator(archiveController: archiveController),
            projectsCoordinator: ProjectsCoordinator(projectsController: projectsController)
        )
        planController.setStoryboardRouter(appRouter)

        let appController = AppController(dataManager: dataManager, appRouter: appRouter,
                                          fatalErrorHandler: FatalErrorHandler(window: window))
        //return appController
    }

    func inject() {

    }
}
