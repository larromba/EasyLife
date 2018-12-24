import Foundation

protocol AppControlling {
    // 🦄
}

final class AppController: AppControlling {
    private let dataManager: CoreDataManaging
    private let planCoordinator: PlanCoordinating
    private let fatalErrorHandler: FatalErrorHandler?

    init(dataManager: CoreDataManaging, planCoordinator: PlanCoordinating, fatalErrorHandler: FatalErrorHandler) {
        self.dataManager = dataManager
        self.planCoordinator = planCoordinator
        self.fatalErrorHandler = fatalErrorHandler
        setupNotifications()
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)),
                                               name: .UIApplicationWillTerminate, object: nil)
    }

    @objc
    private func applicationWillTerminate(_ notification: Notification) {
        _ = dataManager.save(context: .main)
    }
}
