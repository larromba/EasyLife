import AsyncAwait
import CoreData
import Foundation
@testable import EasyLife

final class AppTestEnvironment: TestEnvironment {
    enum TodoItemType {
        case empty
        case missed
        case today
        case later
        case laterCustom(Int)
    }

    var viewController: PlanViewControlling
    var navigationController: UINavigationController
    var window: UIWindow
    var persistentContainer: NSPersistentContainer
    var isLoaded: Bool
    var badge: Badge
    var now: Date

    private(set) var dataManager: CoreDataManaging!
    private(set) var repository: PlanRepositoring!
    private(set) var alertController: AlertControlling!
    private(set) var planController: PlanControlling!
    private(set) var itemDetailRepository: ItemDetailRepository!
    private(set) var blockedRepository: BlockedRepository!
    private(set) var itemDetailController: ItemDetailController!
    private(set) var blockedController: BlockedController!
    private(set) var planCoordinator: PlanCoordinator!
    private(set) var archiveRepository: ArchiveRepository!
    private(set) var archiveController: ArchiveController!
    private(set) var projectsRepository: ProjectsRepository!
    private(set) var projectsController: ProjectsController!
    private(set) var archiveCoordinator: ArchiveCoordinator!
    private(set) var projectsCoordinator: ProjectsCoordinator!
    private(set) var appRouter: AppRouter!
    private(set) var fatalErrorHandler: FatalErrorHandler!
    private(set) var appController: AppController!

    init(viewController: PlanViewControlling = MockPlanViewController(),
         navigationController: UINavigationController = UINavigationController(),
         window: UIWindow = UIWindow(),
         persistentContainer: NSPersistentContainer = .mock(),
         isLoaded: Bool = true,
         badge: Badge = MockBadge(),
         now: Date = Date()) {
        self.viewController = viewController
        self.navigationController = navigationController
        self.window = window
        self.persistentContainer = persistentContainer
        self.isLoaded = isLoaded
        self.badge = badge
        self.now = now
    }

    func inject() {
        dataManager = CoreDataManager(persistentContainer: persistentContainer, isLoaded: isLoaded)
        repository = PlanRepository(dataManager: dataManager)
        alertController = AlertController(presenter: viewController)
        planController = PlanController(viewController: viewController,
                                        alertController: alertController,
                                        repository: repository,
                                        badge: badge)
        blockedRepository = BlockedRepository(dataManager: dataManager)
        itemDetailRepository = ItemDetailRepository(dataManager: dataManager, now: now)
        itemDetailController = ItemDetailController(repository: itemDetailRepository)
        blockedController = BlockedController(repository: blockedRepository)
        planCoordinator = PlanCoordinator(
            navigationController: navigationController,
            planController: planController,
            itemDetailController: itemDetailController,
            blockedController: blockedController
        )
        archiveRepository = ArchiveRepository(dataManager: dataManager)
        archiveController = ArchiveController(repository: archiveRepository)
        projectsRepository = ProjectsRepository(dataManager: dataManager)
        projectsController = ProjectsController(repository: projectsRepository)
        archiveCoordinator = ArchiveCoordinator(archiveController: archiveController)
        projectsCoordinator = ProjectsCoordinator(projectsController: projectsController)
        appRouter = AppRouter(
            planCoordinator: planCoordinator,
            archiveCoordinator: archiveCoordinator,
            projectsCoordinator: projectsCoordinator
        )
        planController.setStoryboardRouter(appRouter)
        fatalErrorHandler = FatalErrorHandler(window: window)
        appController = AppController(
            dataManager: dataManager,
            appRouter: appRouter,
            fatalErrorHandler: fatalErrorHandler
        )
    }

    func start() {
        (viewController as? UIViewController)?.prepareView()
        planController.start()
    }

    func addToWindow() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func todoItem(type: TodoItemType, name: String? = nil, repeatState: RepeatState? = nil,
                  notes: String? = nil, project: Project? = nil, isTransient: Bool = false,
                  isDone: Bool = false) -> TodoItem {
        let item = isTransient ?
            dataManager.insertTransient(entityClass: TodoItem.self, context: .main).value! :
            dataManager.insert(entityClass: TodoItem.self, context: .main)
        item.name = name
        item.repeatState = repeatState
        item.notes = notes
        item.project = project
        item.done = isDone
        switch type {
        case .empty: item.date = nil
        case .later: item.date = Date().plusDays(2)
        case .laterCustom(let day): item.date = Date().plusDays(day)
        case .missed: item.date = Date().minusDays(2)
        case .today: item.date = Date()
        }
        return item
    }

    func project(priority: Int16, name: String? = nil) -> Project {
        let project = dataManager.insert(entityClass: Project.self, context: .main)
        project.priority = priority
        project.name = name
        return project
    }
}
