import Foundation

protocol AppControlling {
    func start()
    func applicationWillTerminate()
}

final class AppController: AppControlling {
    private let dataManager: CoreDataManaging
    private let appRouter: AppRouter
    private let fatalErrorHandler: FatalErrorHandler

    init(dataManager: CoreDataManaging, appRouter: AppRouter, fatalErrorHandler: FatalErrorHandler) {
        self.dataManager = dataManager
        self.appRouter = appRouter
        self.fatalErrorHandler = fatalErrorHandler
    }

    func start() {
        appRouter.start()
    }

    func applicationWillTerminate() {
        _ = dataManager.save(context: .main) // TODO: does this work?
    }
}
