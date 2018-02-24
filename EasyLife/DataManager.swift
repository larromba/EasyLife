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
    
    init() {
        persistentContainer = NSPersistentContainer(name: "EasyLife")
    }

    // MARK: - public
    
    func insert<T:NSManagedObject>(entityClass: T.Type) -> T? {
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        return insert(entityName: entityName) as? T
    }

    func insert(entityName: String) -> NSManagedObject? {
        let context = mainContext
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            log("couldnt make entityDescription for: \(entityName)")
            let error = NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "couldnt make entityDescription for: \(entityName)"
                ])
            Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
            return nil
        }
        return NSManagedObject(entity: entityDescription, insertInto: context)
    }

    func copy(_ entity: NSManagedObject) -> NSManagedObject? {
        guard let name = entity.entity.name else {
            return nil
        }
        guard let copy = insert(entityName: name) else {
            return nil
        }
        let context = mainContext
        guard let attributess = NSEntityDescription.entity(forEntityName: name, in: context)?.attributesByName,
            let relationships = NSEntityDescription.entity(forEntityName: name, in: context)?.relationshipsByName else {
            return nil
        }
        attributess.forEach { (key: String, desc: NSAttributeDescription) in
            copy.setValue(entity.value(forKey: key), forKey: key)
        }
        relationships.forEach { (key: String, desc: NSRelationshipDescription) in
            if desc.isToMany {
                log("deepcopy coredata to-many relationships not yet supported")
                //TODO: this
                // https://stackoverflow.com/questions/2730832/how-can-i-duplicate-or-copy-a-core-data-managed-object
//                let sourceSet = entity.mutableSetValue(forKey: key)
//                let copySet = copy.mutableSetValue(forKey: key)
//                let e = sourceSet.objectEnumerator()
//                let relatedObject: NSManagedObject
//                while (relatedObject != e.nextObject()) {
//                    let relatedObject
//                }
            } else {
                copy.setValue(entity.value(forKey: key), forKey: key)
            }
        }
        return copy
    }
    
    func delete<T:NSManagedObject>(_ entity:T)  {
        let context = mainContext
        context.delete(entity)
    }
    
    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: String? = nil, isAscending: Bool = true, predicate: NSPredicate? = nil, success: @escaping FetchSuccess, failure: Failure? = nil) {
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        if (sortBy != nil) {
            request.sortDescriptors = [NSSortDescriptor(key:sortBy, ascending:isAscending)]
        }
        
        let context = mainContext
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
    
    func save(success: Success? = nil, failure: Failure? = nil) {
        let context = mainContext
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
