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
                let blockedByRepository = BlockedByRepository(dataManager: dataManager)
                let itemDetailRepository = ItemDetailRepository(dataManager: dataManager, now: Date())
                let planCoordinator = PlanCoordinator(
                    navigationController: navigationController,
                    planController: planController,
                    itemDetailController: ItemDetailController(repository: itemDetailRepository),
                    blockedByController: BlockedByController(repository: blockedByRepository)
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
                completion(.success(appController))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
