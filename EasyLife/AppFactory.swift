import AsyncAwait
import CoreData
import UIKit

enum AppFactory {
    // swiftlint:disable function_body_length
    static func make(window: UIWindow, navigationController: UINavigationController,
                     planViewController: PlanViewControlling) -> Async<Appable, Error> {
        return Async { completion in
            async({
                let persistentContainer = NSPersistentContainer(name: "EasyLife")
                let dataContextProvider = DataContextProvider(persistentContainer: persistentContainer)
                try await(dataContextProvider.load())
                #if DEBUG
                if __isSnapshot {
                    try setSnapshotData(dataContextProvider: dataContextProvider)
                }
                #endif

                let badge = AppBadge()
                let planRepository = PlanRepository(dataContextProvider: dataContextProvider)
                let holidayRepository = HolidayRepository()
                let planController = PlanController(
                    viewController: planViewController,
                    planRepository: planRepository,
                    holidayRepository: holidayRepository,
                    badge: badge
                )
                let itemDetailRepository = ItemDetailRepository(dataContextProvider: dataContextProvider)
                let blockedByRepository = BlockedByRepository()
                let holidayController = HolidayController(
                    presenter: planViewController,
                    holidayRepository: holidayRepository,
                    badge: badge
                )
                let planCoordinator = PlanCoordinator(
                    navigationController: navigationController,
                    planController: planController,
                    planAlertController: AlertController(presenter: planViewController),
                    itemDetailController: ItemDetailController(repository: itemDetailRepository),
                    blockedByController: BlockedByController(repository: blockedByRepository)
                )
                let focusRepository = FocusRepository(
                    dataContextProvider: dataContextProvider,
                    planRepository: planRepository
                )
                let alarmNotificationHandler = AlarmNotificationHandler()
                let focusController = FocusController(
                    repository: focusRepository,
                    alarm: Alarm(),
                    alarmNotificationHandler: alarmNotificationHandler
                )
                let archiveRepository = ArchiveRepository(dataContextProvider: dataContextProvider)
                let archiveController = ArchiveController(repository: archiveRepository)
                let projectsRepository = ProjectsRepository(dataContextProvider: dataContextProvider)
                let projectsController = ProjectsController(repository: projectsRepository)
                let appRouter = AppRouter(
                    planCoordinator: planCoordinator,
                    focusCoordinator: FocusCoordinator(focusController: focusController),
                    archiveCoordinator: ArchiveCoordinator(archiveController: archiveController),
                    projectsCoordinator: ProjectsCoordinator(projectsController: projectsController),
                    holidayCoordinator: HolidayCoordinator(holidayController: holidayController),
                    alarmNotificationHandler: alarmNotificationHandler
                )
                let app = App(
                    dataContextProvider: dataContextProvider,
                    appRouter: appRouter,
                    fatalErrorHandler: FatalErrorHandler(window: window)
                )
                completion(.success(app))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    // MARK: - private

    #if DEBUG
    private static func setSnapshotData(dataContextProvider: DataContextProviding) throws {
        let context = dataContextProvider.mainContext()
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
