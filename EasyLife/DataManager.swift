//
//  DataManager.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
import CoreData

class DataManager {
    typealias FetchSuccess = ([Any]?) -> Void
    typealias Success = () -> Void
    typealias Failure = (Error?) -> Void
    
    static let shared = DataManager()
    var persistentContainer: NSPersistentContainer
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    init() {
        persistentContainer = NSPersistentContainer(name: "EasyLife")
    }

    // MARK: - public
    
    func insert<T:NSManagedObject>(entityClass: T.Type, context: NSManagedObjectContext, transient: Bool = false) -> T? {
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        return insert(entityName: entityName, context: context, transient: transient) as? T
    }

    func insert(entityName: String, context: NSManagedObjectContext, transient: Bool = false) -> NSManagedObject? {
        if transient {
            guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
                let message = "couldnt create NSEntityDescription for: \(entityName)"
                log(message)
                let error = NSError(domain: "", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: message
                    ])
                Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
                return nil
            }
            return NSManagedObject(entity: entityDescription, insertInto: nil)
        } else {
            return NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        }
    }

    func copy(_ entity: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject? {
        guard let name = entity.entity.name else {
            return nil
        }
        guard let copy = insert(entityName: name, context: context) else {
            return nil
        }
        guard let attributess = NSEntityDescription.entity(forEntityName: name, in: context)?.attributesByName,
            let relationships = NSEntityDescription.entity(forEntityName: name, in: context)?.relationshipsByName else {
            return nil
        }
        attributess.forEach { (key: String, desc: NSAttributeDescription) in
            copy.setValue(entity.value(forKey: key), forKey: key)
        }
        relationships.forEach { (key: String, desc: NSRelationshipDescription) in
            // see https://stackoverflow.com/questions/2730832/how-can-i-duplicate-or-copy-a-core-data-managed-object
            if desc.isToMany {
                copy.setValue(entity.mutableSetValue(forKey: key), forKey: key)
            } else {
                copy.setValue(entity.value(forKey: key), forKey: key)
            }
        }
        return copy
    }
    
    func delete<T:NSManagedObject>(_ entity:T, context: NSManagedObjectContext)  {
        context.delete(entity)
    }
    
    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: [NSSortDescriptor]? = nil, context: NSManagedObjectContext, predicate: NSPredicate? = nil, success: @escaping FetchSuccess, failure: Failure? = nil) {
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = sortBy
        context.perform({ [weak context] in
            do {
                let result = try context?.fetch(request)
                success(result)
            } catch {
                log(error)
                failure?(error)
                Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
            }
        })
    }
    
    func load(success: Success? = nil, failure: Failure? = nil) {
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            guard let error = error else {
                success?()
                return
            }
            failure?(error)
            Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
            NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)
        })
    }
    
    func save(context: NSManagedObjectContext, success: Success? = nil, failure: Failure? = nil) {
        guard context.hasChanges else {
            return
        }
        context.perform({ [weak context] in
            do {
                try context?.save()
                success?()
            } catch {
                failure?(error)
                Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
                NotificationCenter.default.post(name: .applicationDidReceiveFatalError, object: error)
            }
        })
    }
}
