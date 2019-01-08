import AsyncAwait
import CoreData
import Foundation
@testable import EasyLife

final class PlanEnvironment: TestEnvironment {
    var viewController: PlanViewControlling
    var persistentContainer: NSPersistentContainer
    var badge: Badge

    private(set) var dataManager: CoreDataManager!
    private(set) var repository: PlanRepositoring!
    private(set) var alertController: AlertControlling!
    private(set) var planController: PlanControlling!

    init(viewController: PlanViewControlling = MockPlanViewController(),
         persistentContainer: NSPersistentContainer,
         badge: Badge = MockBadge()) {
        self.viewController = viewController
        self.persistentContainer = persistentContainer
        self.badge = badge
    }

    func inject() {
        dataManager = CoreDataManager(persistentContainer: persistentContainer, isLoaded: true)
        repository = PlanRepository(dataManager: dataManager)
        alertController = AlertController(presenter: viewController)
        planController = PlanController(viewController: viewController,
                                        alertController: alertController,
                                        repository: repository,
                                        badge: badge)
        planController.start()
    }
}
