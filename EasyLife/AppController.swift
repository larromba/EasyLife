import AsyncAwait
import Foundation
import Logging

// sourcery: name = AppController
protocol AppControlling: Mockable {
    func start()
    func applicationWillTerminate()
}

final class AppController: AppControlling {
    private let dataManager: DataManaging
    private let appRouter: AppRouting
    private let fatalErrorHandler: FatalErrorHandler

    init(dataManager: DataManaging, appRouter: AppRouting, fatalErrorHandler: FatalErrorHandler) {
        self.dataManager = dataManager
        self.appRouter = appRouter
        self.fatalErrorHandler = fatalErrorHandler
    }

    func start() {
        appRouter.start()
    }

    func applicationWillTerminate() {
        async({
            let context = self.dataManager.mainContext()
            _ = try await(context.save())
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }
}
