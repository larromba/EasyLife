import AsyncAwait
import Foundation
import Logging

// sourcery: name = AppController
protocol AppControlling: Mockable {
    func start()
    func applicationWillTerminate()
}

final class AppController: AppControlling {
    private let dataContextProvider: DataContextProviding
    private let appRouter: AppRouting
    private let fatalErrorHandler: FatalErrorHandler

    init(dataContextProvider: DataContextProviding, appRouter: AppRouting, fatalErrorHandler: FatalErrorHandler) {
        self.dataContextProvider = dataContextProvider
        self.appRouter = appRouter
        self.fatalErrorHandler = fatalErrorHandler
    }

    func start() {
        appRouter.start()
    }

    func applicationWillTerminate() {
        async({
            _ = try await(self.dataContextProvider.mainContext().save())
        }, onError: { error in
            logError(error.localizedDescription)
        })
    }
}
