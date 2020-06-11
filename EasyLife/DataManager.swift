import AsyncAwait
import CoreData
import Foundation
import Logging
import Result

// sourcery: name = DataManager
protocol DataManaging: AnyObject, Mockable {
    func mainContext() -> DataContexting
    func backgroundContext() -> DataContexting
    func childContext(thread: ThreadType) -> DataContexting
    func load() -> Async<Void>
}

// TODO: move to new repo?
//
// CoreData is tricky. Here's some tips:
//
// - To check concurrency, add this debug flag to target run settings:
//   -com.apple.CoreData.ConcurrencyDebug 1
//
// - Use the main context for fetch requests. This means NSManagedObject instances can then be manipulated on the main
//   thread without violating concurrency rules
//
// - Use a background context for long-running processes, so it doesn't block the main thread. Remember to save any
//   changes to propagate them to the parent. Then save the parent
//

// TODO: rename DataProviding
final class DataManager: DataManaging {
    private let persistentContainer: NSPersistentContainer
    private let notificationCenter: NotificationCenter

    init(persistentContainer: NSPersistentContainer, isLoaded: Bool = false,
         notificationCenter: NotificationCenter = .default) {
        self.persistentContainer = persistentContainer
        self.notificationCenter = notificationCenter
    }

    func mainContext() -> DataContexting {
        return DataContext(managedObjectContext: persistentContainer.viewContext,
                           notificationCenter: notificationCenter)
    }

    func backgroundContext() -> DataContexting {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return DataContext(managedObjectContext: context, notificationCenter: notificationCenter)
    }

    func childContext(thread: ThreadType) -> DataContexting {
        let context: NSManagedObjectContext
        switch thread {
        case .main: context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        case .background: context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        }
        context.parent = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        return DataContext(managedObjectContext: context, notificationCenter: notificationCenter)
    }

    func load() -> Async<Void> {
        return Async { completion in
            let container = self.persistentContainer
            container.loadPersistentStores(completionHandler: { [unowned container] _, error in
                if let error = error {
                    completion(.failure(CoreDataError.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                    return
                }
                container.viewContext.automaticallyMergesChangesFromParent = true
                completion(.success(()))
            })
        }
    }
}
