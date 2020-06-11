import AsyncAwait
import CoreData
import UIKit

enum AppControllerFactory {
    static func make(window: UIWindow, navigationController: UINavigationController,
                     planViewController: PlanViewControlling) -> Async<AppControlling> {
        return Async { completion in
            async({
                let persistentContainer = NSPersistentContainer(name: "EasyLife")
                let dataManager = DataManager(persistentContainer: persistentContainer)
                #if DEBUG
                if __isSnapshot {
                    try setSnapshotData(dataManager: dataManager)
                }
                #endif
                try await(dataManager.load())

                let planRepository = PlanRepository(dataManager: dataManager)
                let planController = PlanController(
                    viewController: planViewController,
                    alertController: AlertController(presenter: planViewController),
                    repository: planRepository,
                    badge: AppBadge()
                )
                let itemDetailRepository = ItemDetailRepository(dataManager: dataManager, now: Date())
                let blockedByRepository = BlockedByRepository(dataManager: dataManager)
                let planCoordinator = PlanCoordinator(
                    navigationController: navigationController,
                    planController: planController,
                    itemDetailController: ItemDetailController(repository: itemDetailRepository),
                    blockedByController: BlockedByController(repository: blockedByRepository)
                )

                let focusController = FocusController(repository: planRepository)
                let archiveRepository = ArchiveRepository(dataManager: dataManager)
                let archiveController = ArchiveController(repository: archiveRepository)
                let projectsRepository = ProjectsRepository(dataManager: dataManager)
                let projectsController = ProjectsController(repository: projectsRepository)

                let appRouter = AppRouter(
                    planCoordinator: planCoordinator,
                    focusCoordinator: FocusCoordinator(focusController: focusController),
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

    // MARK: - private

    #if DEBUG
    private static func setSnapshotData(dataManager: DataManaging) throws {
        let context = dataManager.mainContext()
        try await(context.deleteAll([TodoItem.self, Project.self]))

        // plan section

        let missed1 = context.insert(entityClass: TodoItem.self)
        missed1.date = Date().addingTimeInterval(-24 * 60 * 60)
        missed1.name = "send letter"

        let now1 = context.insert(entityClass: TodoItem.self)
        now1.date = Date()
        now1.name = "fix bike"

        let now2 = context.insert(entityClass: TodoItem.self)
        now2.date = Date()
        now2.name = "get party food!"

        let later1 = context.insert(entityClass: TodoItem.self)
        later1.date = Date().addingTimeInterval(24 * 60 * 60)
        later1.name = "phone mum"

        let later2 = context.insert(entityClass: TodoItem.self)
        later2.date = Date().addingTimeInterval(24 * 60 * 60)
        later2.name = "clean flat"

        let later3 = context.insert(entityClass: TodoItem.self)
        later3.date = Date().addingTimeInterval(24 * 60 * 60)
        later3.name = "call landlord"

        // projects section

        let project1 = context.insert(entityClass: Project.self)
        project1.name = "Fitness"
        project1.priority = 0

        let project2 = context.insert(entityClass: Project.self)
        project2.name = "Social"
        project2.priority = 1

        let project3 = context.insert(entityClass: Project.self)
        project3.name = "Learn German"
        project3.priority = Project.defaultPriority

        // archive section

        let archive1 = context.insert(entityClass: TodoItem.self)
        archive1.name = "pay rent"
        archive1.done = true

        let archive2 = context.insert(entityClass: TodoItem.self)
        archive2.name = "buy newspaper"
        archive2.done = true

        try await(context.save())
    }
    #endif
}
