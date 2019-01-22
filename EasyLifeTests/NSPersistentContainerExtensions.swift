import CoreData

extension NSPersistentContainer {
    static func inMemory(at url: URL? = nil) throws -> NSPersistentContainer {
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

    static func mock() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "EasyLife")
        let description = container.persistentStoreDescriptions.first!
        description.type = NSInMemoryStoreType
        let group = DispatchGroup()
        group.enter()
        container.loadPersistentStores(completionHandler: { (_: NSPersistentStoreDescription, error: Error?) in
            assert(error == nil)
            group.leave()
        })
        return container
    }
}
