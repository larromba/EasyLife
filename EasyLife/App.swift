import AsyncAwait
import Logging
import UIKit

// sourcery: name = App
protocol Appable: Mockable {
    func start()
    func applicationWillTerminate()
    func processShortcutItem(_ item: UIApplicationShortcutItem)
}

final class App: Appable {
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

    func processShortcutItem(_ item: UIApplicationShortcutItem) {
        guard let item = ShortcutItem(rawValue: item.type) else {
            assertionFailure("unknown shortcut item")
            return
        }
        switch item {
        case .newTodoItem: appRouter.routeToNewTodoItem()
        }
    }
}
