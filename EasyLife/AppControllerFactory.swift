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

                #if DEBUG
                if __isSnapshot {
                    try await(dataManager.reset())

                    // plan section

                    let missed1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    missed1.date = Date().addingTimeInterval(-24 * 60 * 60)
                    missed1.name = "send letter"

                    let now1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    now1.date = Date()
                    now1.name = "fix bike"

                    let now2 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    now2.date = Date()
                    now2.name = "get party food!"

                    let later1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    later1.date = Date().addingTimeInterval(24 * 60 * 60)
                    later1.name = "phone mum"

                    let later2 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    later2.date = Date().addingTimeInterval(24 * 60 * 60)
                    later2.name = "clean flat"

                    let later3 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    later3.date = Date().addingTimeInterval(24 * 60 * 60)
                    later3.name = "call landlord"

                    // projects section

                    let project1 = dataManager.insert(entityClass: Project.self, context: .main)
                    project1.name = "Fitness"
                    project1.priority = 0

                    let project2 = dataManager.insert(entityClass: Project.self, context: .main)
                    project2.name = "Social"
                    project2.priority = 1

                    let project3 = dataManager.insert(entityClass: Project.self, context: .main)
                    project3.name = "Learn German"
                    project3.priority = -1

                    // archive section

                    let archive1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    archive1.name = "pay rent"
                    archive1.done = true

                    let archive2 = dataManager.insert(entityClass: TodoItem.self, context: .main)
                    archive2.name = "buy newspaper"
                    archive2.done = true

                    try await(dataManager.save(context: .main))
                }
                #endif

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
