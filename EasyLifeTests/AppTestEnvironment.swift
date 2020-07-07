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
    var alarm: Alarming
    var userDefaults: UserDefaults
    var alarmNotificationHandler: AlarmNotificationHandling

    private(set) var appRouter: AppRouting!
    private(set) var fatalErrorHandler: FatalErrorHandler!
    private(set) var appController: AppControlling!
    private(set) var dataContextProvider: DataContextProviding!
    private(set) var childContext: DataContexting!
    private(set) var alertController: AlertControlling!
    private(set) var planRepository: PlanRepositoring!
    private(set) var planController: PlanControlling!
    private(set) var planCoordinator: PlanCoordinating!
    private(set) var itemDetailRepository: ItemDetailRepositoring!
    private(set) var itemDetailController: ItemDetailControlling!
    private(set) var focusRepository: FocusRepositoring!
    private(set) var focusController: FocusControlling!
    private(set) var focusCoordinator: FocusCoordinating!
    private(set) var blockedByRepository: BlockedByRepositoring!
    private(set) var blockedByController: BlockedByControlling!
    private(set) var holidayController: HolidayControlling!
    private(set) var holidayRepository: HolidayRepositoring!
    private(set) var archiveRepository: ArchiveRepositoring!
    private(set) var archiveController: ArchiveControlling!
    private(set) var archiveCoordinator: ArchiveCoordinating!
    private(set) var projectsRepository: ProjectsRepositoring!
    private(set) var projectsController: ProjectsControlling!
    private(set) var projectsCoordinator: ProjectsCoordinating!

    init(viewController: PlanViewControlling = MockPlanViewController(),
         navigationController: UINavigationController = UINavigationController(),
         window: UIWindow = UIWindow(),
         persistentContainer: NSPersistentContainer = .mock(),
         badge: Badge = MockAppBadge(),
         alarm: Alarming = MockAlarm(),
         userDefaults: UserDefaults = .mock,
         alarmNotificationHandler: AlarmNotificationHandling = MockAlarmNotificationHandler()) {
        self.viewController = viewController
        self.navigationController = navigationController
        self.window = window
        self.persistentContainer = persistentContainer
        self.badge = badge
        self.alarm = alarm
        self.userDefaults = userDefaults
        self.alarmNotificationHandler = alarmNotificationHandler
    }

    // swiftlint:disable function_body_length
    func inject() {
        dataContextProvider = DataContextProvider(persistentContainer: persistentContainer)
        childContext = dataContextProvider.childContext(thread: .main)
        planRepository = PlanRepository(dataContextProvider: dataContextProvider)
        holidayRepository = HolidayRepository(userDefaults: userDefaults)
        alertController = AlertController(presenter: viewController)
        planController = PlanController(
            viewController: viewController,
            planRepository: planRepository,
            holidayRepository: holidayRepository,
            badge: badge
        )
        blockedByRepository = BlockedByRepository()
        itemDetailRepository = ItemDetailRepository(dataContextProvider: dataContextProvider)
        itemDetailController = ItemDetailController(repository: itemDetailRepository)
        blockedByController = BlockedByController(repository: blockedByRepository)
        holidayController = HolidayController(
            presenter: viewController,
            holidayRepository: holidayRepository,
            badge: badge
        )
        planCoordinator = PlanCoordinator(
            navigationController: navigationController,
            planController: planController,
            planAlertController: alertController,
            itemDetailController: itemDetailController,
            blockedByController: blockedByController,
            holidayController: holidayController
        )
        focusRepository = FocusRepository(dataContextProvider: dataContextProvider, planRepository: planRepository)
        focusController = FocusController(
            repository: focusRepository,
            alarm: alarm,
            alarmNotificationHandler: alarmNotificationHandler
        )
        focusCoordinator = FocusCoordinator(focusController: focusController)
        archiveRepository = ArchiveRepository(dataContextProvider: dataContextProvider)
        archiveController = ArchiveController(repository: archiveRepository)
        projectsRepository = ProjectsRepository(dataContextProvider: dataContextProvider)
        projectsController = ProjectsController(repository: projectsRepository)
        archiveCoordinator = ArchiveCoordinator(archiveController: archiveController)
        projectsCoordinator = ProjectsCoordinator(projectsController: projectsController)
        appRouter = AppRouter(
            planCoordinator: planCoordinator,
            focusCoordinator: focusCoordinator,
            archiveCoordinator: archiveCoordinator,
            projectsCoordinator: projectsCoordinator,
            alarmNotificationHandler: alarmNotificationHandler
        )
        planController.setRouter(appRouter)
        fatalErrorHandler = FatalErrorHandler(window: window)
        appController = AppController(
            dataContextProvider: dataContextProvider,
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
        let context = isTransient ? childContext! : dataContextProvider.mainContext()
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
        let project = dataContextProvider.mainContext().insert(entityClass: Project.self)
        project.priority = priority
        project.name = name
        return project
    }
}
