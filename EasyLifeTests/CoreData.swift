import CoreData

extension NSPersistentContainer {
    static func test(url: URL? = nil) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "EasyLife")
        let description = container.persistentStoreDescriptions.first!
        description.type = NSInMemoryStoreType
        if let url = url {
            description.url = url
        }
        let group = DispatchGroup()
        group.enter()
        var loadError: Error?
        container.loadPersistentStores(completionHandler: { (_: NSPersistentStoreDescription, error: Error?) in
            loadError = error
            group.leave()
        })
        if let loadError = loadError {
            throw loadError
        }
        return container
    }
}

//extension NSManagedObjectContext {
//    class var test: NSManagedObjectContext {
//        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
//        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
//        do {
//            try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
//        } catch {
//            fatalError("Adding in-memory persistent store failed")
//        }
//        
//        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
//        return managedObjectContext
//    }
//}
