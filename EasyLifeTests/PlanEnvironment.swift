import CoreData
import Foundation
@testable import EasyLife

final class PlanEnvironment: TestEnvironment {
    var viewController: PlanViewControlling
    var persistentContainer: NSPersistentContainer
    var badge: Badge

    private(set) var planController: PlanControlling!
    private(set) var alertController: AlertControlling!
    private(set) var repository: PlanRepositoring!
    private(set) var dataManager: CoreDataManager!

    init(viewController: PlanViewControlling,
         persistentContainer: NSPersistentContainer,
         badge: Badge) {
        self.viewController = viewController
        self.persistentContainer = persistentContainer
        self.badge = badge
    }

    func inject() {
        dataManager = CoreDataManager(persistentContainer: persistentContainer)
        repository = PlanRepository(dataManager: dataManager)
        alertController = AlertController(presenter: viewController)
        planController = PlanController(viewController: viewController,
                                        alertController: alertController,
                                        repository: repository,
                                        badge: badge)
    }
}
