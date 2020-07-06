import AsyncAwait
import CoreData
import Foundation
import Logging

// sourcery: name = DataContextProvider
protocol DataContextProviding: AnyObject, Mockable {
    func mainContext() -> DataContexting
    func backgroundContext() -> DataContexting
    func childContext(thread: ThreadType) -> DataContexting
    func load() -> Async<Void, DataError>
}

//
// CoreData is tricky. Here's some tips:
//
// - To check concurrency, add this debug flag to target run settings:
//   -com.apple.CoreData.ConcurrencyDebug 1
//
// - Use the main context for fetch requests. This means NSManagedObject instances can then be manipulated on the main
//   thread without violating concurrency rules. Make this common practise.
//
// - Use a background context for long-running processes so you don't block the main thread.
//   Save the bg context, then the parent context, to propagate changes.
//
// - Use child processes when you have discardable data (e.g. forms).
//   Save the child context, then the parent context, to propagate changes.
//
final class DataContextProvider: DataContextProviding {
    private let persistentContainer: NSPersistentContainer
    private let notificationCenter: NotificationCenter

    init(persistentContainer: NSPersistentContainer, notificationCenter: NotificationCenter = .default) {
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

    func load() -> Async<Void, DataError> {
        return Async { completion in
            let container = self.persistentContainer
            container.loadPersistentStores(completionHandler: { [unowned container] _, error in
                if let error = error {
                    completion(.failure(.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                    return
                }
                container.viewContext.automaticallyMergesChangesFromParent = true
                completion(.success(()))
            })
        }
    }
}
