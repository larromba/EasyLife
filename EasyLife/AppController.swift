import Foundation

protocol AppControlling {
    func start()
    func applicationWillTerminate()
}

final class AppController: AppControlling {
    private let dataManager: CoreDataManaging
    private let planCoordinator: PlanCoordinating
    private let fatalErrorHandler: FatalErrorHandler

    init(dataManager: CoreDataManaging, planCoordinator: PlanCoordinating, fatalErrorHandler: FatalErrorHandler) {
        self.dataManager = dataManager
        self.planCoordinator = planCoordinator
        self.fatalErrorHandler = fatalErrorHandler
    }

    func start() {
        planCoordinator.start()
    }

    func applicationWillTerminate() {
        _ = dataManager.save(context: .main) // TODO: does this work?
    }
}
