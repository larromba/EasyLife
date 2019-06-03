import AsyncAwait
import Foundation
import Logging

// sourcery: name = AppController
protocol AppControlling: Mockable {
    func start()
    func applicationWillTerminate()
}

final class AppController: AppControlling {
    private let dataManager: CoreDataManaging
    private let appRouter: AppRouting
    private let fatalErrorHandler: FatalErrorHandler

    init(dataManager: CoreDataManaging, appRouter: AppRouting, fatalErrorHandler: FatalErrorHandler) {
        self.dataManager = dataManager
        self.appRouter = appRouter
        self.fatalErrorHandler = fatalErrorHandler
    }

    func start() {
        appRouter.start()
    }

    func applicationWillTerminate() {
        async({
            _ = try await(self.dataManager.save(context: .main))
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }
}
