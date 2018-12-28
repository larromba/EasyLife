import AsyncAwait
import CoreData
import UIKit

enum AppControllerFactory {
    static func make(window: UIWindow, navigationController: UINavigationController,
                     planViewController: PlanViewControlling) -> Async<AppControlling> {
        return Async { completion in
            async({
                let persistentContainer = NSPersistentContainer(name: "EasyLife")
                let dataManager = CoreDataManager(persistentContainer: persistentContainer)
                try await(dataManager.load())

                let planController = PlanController(
                    viewController: planViewController,
                    alertController: AlertController(presenter: planViewController),
                    repository: PlanRepository(dataManager: dataManager),
                    badge: AppBadge()
                )
                let blockedRepository = BlockedRepository(dataManager: dataManager)
                let blockedController = BlockedController(repository: blockedRepository)
                let itemDetailRepository = ItemDetailRepository(dataManager: dataManager, now: Date())
                let itemDetailController = ItemDetailController(repository: itemDetailRepository)
                let planCoordinator = PlanCoordinator(navigationController: navigationController,
                                                      planController: planController,
                                                      itemDetailController: itemDetailController,
                                                      blockedController: blockedController)

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

                let fatalErrorHandler = FatalErrorHandler(window: window)

                let appController = AppController(dataManager: dataManager, appRouter: appRouter,
                                                  fatalErrorHandler: fatalErrorHandler)
                completion(.success(appController))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
