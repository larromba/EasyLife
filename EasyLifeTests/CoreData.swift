//
//  CoreData.swift
//  EasyLife
//
//  Created by Lee Arromba on 20/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import CoreData

extension NSPersistentContainer {
    class func test(url: URL? = nil) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "EasyLife")
        let description = container.persistentStoreDescriptions.first!
        description.type = NSInMemoryStoreType
        if let url = url {
            description.url = url
        }
        var loadError: Error?
        let group = DispatchGroup()
        group.enter()
        container.loadPersistentStores(completionHandler: { (storeDescription: NSPersistentStoreDescription, error: Error?) in
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
