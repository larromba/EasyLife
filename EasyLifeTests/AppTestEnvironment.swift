import AsyncAwait
import CoreData
@testable import EasyLife
import Foundation
import UIKit

final class AppTestEnvironment: TestEnvironment {
    enum TodoItemType {
        case empty
        case missed
        case today
        case later
        case laterDay(Int)
        case laterDate(Date)
    }

    var window: UIWindow
    var navigationController: UINavigationController
    var viewController: PlanViewControlling
    var persistentContainer: NSPersistentContainer
    var badge: Badge
    var now: Date

    private(set) var appRouter: AppRouting!
    private(set) var fatalErrorHandler: FatalErrorHandler!
    private(set) var appController: AppControlling!
    private(set) var dataProvider: DataContextProviding!
    private(set) var childContext: DataContexting!
    private(set) var alertController: AlertControlling!
    private(set) var planRepository: PlanRepositoring!
    private(set) var planController: PlanControlling!
    private(set) var planCoordinator: PlanCoordinating!
    private(set) var itemDetailRepository: ItemDetailRepositoring!
    private(set) var itemDetailController: ItemDetailControlling!
    private(set) var blockedByRepository: BlockedByRepositoring!
    private(set) var blockedByController: BlockedByControlling!
    private(set) var archiveRepository: ArchiveRepositoring!
    private(set) var archiveController: ArchiveControlling!
    private(set) var archiveCoordinator: ArchiveCoordinating!
    private(set) var projectsRepository: ProjectsRepositoring!
    private(set) var projectsController: ProjectsControlling!
    private(set) var projectsCoordinator: ProjectsCoordinating!
    private(set) var focusController: FocusControlling!
    private(set) var focusCoordinator: FocusCoordinating!

    init(viewController: PlanViewControlling = MockPlanViewController(),
         navigationController: UINavigationController = UINavigationController(),
         window: UIWindow = UIWindow(),
         persistentContainer: NSPersistentContainer = .mock(),
         badge: Badge = MockBadge(),
         now: Date = Date()) {
        self.viewController = viewController
        self.navigationController = navigationController
        self.window = window
        self.persistentContainer = persistentContainer
        self.badge = badge
        self.now = now
    }

    func inject() {
        dataProvider = DataContextProvider(persistentContainer: persistentContainer)
        childContext = dataProvider.childContext(thread: .main)
        planRepository = PlanRepository(dataProvider: dataProvider)
        alertController = AlertController(presenter: viewController)
        planController = PlanController(viewController: viewController,
                                        alertController: alertController,
                                        repository: planRepository,
                                        badge: badge)
        blockedByRepository = BlockedByRepository(dataProvider: dataProvider)
        itemDetailRepository = ItemDetailRepository(dataProvider: dataProvider, now: now)
        itemDetailController = ItemDetailController(repository: itemDetailRepository)
        blockedByController = BlockedByController(repository: blockedByRepository)
        planCoordinator = PlanCoordinator(
            navigationController: navigationController,
            planController: planController,
            itemDetailController: itemDetailController,
            blockedByController: blockedByController
        )
        focusController = FocusController(repository: planRepository)
        focusCoordinator = FocusCoordinator(focusController: focusController)
        archiveRepository = ArchiveRepository(dataProvider: dataProvider)
        archiveController = ArchiveController(repository: archiveRepository)
        projectsRepository = ProjectsRepository(dataProvider: dataProvider)
        projectsController = ProjectsController(repository: projectsRepository)
        archiveCoordinator = ArchiveCoordinator(archiveController: archiveController)
        projectsCoordinator = ProjectsCoordinator(projectsController: projectsController)
        appRouter = AppRouter(
            planCoordinator: planCoordinator,
            focusCoordinator: focusCoordinator,
            archiveCoordinator: archiveCoordinator,
            projectsCoordinator: projectsCoordinator
        )
        planController.setRouter(appRouter)
        fatalErrorHandler = FatalErrorHandler(window: window)
        appController = AppController(
            dataProvider: dataProvider,
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

    func todoItem(type: TodoItemType, name: String? = nil, repeatState: RepeatState = .default,
                  notes: String? = nil, project: Project? = nil, isTransient: Bool = false,
                  isDone: Bool = false, blockedBy: [TodoItem]? = nil) -> TodoItem {
        let context = isTransient ? childContext! : dataProvider.mainContext()
        let item = context.insert(entityClass: TodoItem.self)
        item.name = name
        item.repeatState = repeatState
        item.notes = notes
        item.project = project
        item.done = isDone
        blockedBy?.forEach { item.addToBlockedBy($0) }
        switch type {
        case .empty: item.date = nil
        case .later: item.date = Date().plusDays(2)
        case .laterDay(let day): item.date = Date().plusDays(day)
        case .laterDate(let date): item.date = date
        case .missed: item.date = Date().minusDays(2)
        case .today: item.date = Date()
        }
        return item
    }

    func project(priority: Int16, name: String? = nil) -> Project {
        let project = dataProvider.mainContext().insert(entityClass: Project.self)
        project.priority = priority
        project.name = name
        return project
    }
}
