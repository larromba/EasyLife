import CoreData
@testable import EasyLife
import XCTest

extension NSPersistentContainer {
    static func inMemory(at url: URL? = nil) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "EasyLife")
        let description = container.persistentStoreDescriptions.first!
        description.type = NSInMemoryStoreType
        description.url = url
        try container.loadPersistentStoresSync()
        return container
    }

    static func mock() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "EasyLife")
        let description = container.persistentStoreDescriptions.first!
        description.type = NSInMemoryStoreType
        XCTAssertNoThrow(try container.loadPersistentStoresSync())
        return container
    }

    static func mock(fetchError: Error) -> NSPersistentContainer {
        return ErrorPersistentContainer(error: fetchError)
    }

    func loadPersistentStoresSync() throws {
        var error: Error!
        let group = DispatchGroup()
        group.enter()
        loadPersistentStores(completionHandler: { (_: NSPersistentStoreDescription, err: Error?) in
            error = err
            group.leave()
        })
        if let error = error {
            throw error
        }
    }
}

// MARK: - private

private final class ErrorPersistentContainer: NSPersistentContainer {
    private let error: Error

    init(error: Error) {
        self.error = error
        let url = Bundle.safeMain.url(forResource: "EasyLife", withExtension: "momd")!
        let mom = NSManagedObjectModel(contentsOf: url)!
        super.init(name: "EasyLife", managedObjectModel: mom)
        XCTAssertNoThrow(try loadPersistentStoresSync())
    }

    override var viewContext: NSManagedObjectContext {
        let context = ErrorManagedObjectContext(error: error, concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        return context
    }

    override func newBackgroundContext() -> NSManagedObjectContext {
        let context = ErrorManagedObjectContext(error: error, concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        return context
    }
}

// MARK: - private

private final class ErrorManagedObjectContext: NSManagedObjectContext {
    private let error: Error

    init(error: Error, concurrencyType: NSManagedObjectContextConcurrencyType) {
        self.error = error
        super.init(concurrencyType: concurrencyType)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func fetch(_ request: NSFetchRequest<NSFetchRequestResult>) throws -> [Any] {
        throw error
    }
}
