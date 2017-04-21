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
    typealias Success = (Void) -> Void
    typealias Failure = (Error?) -> Void
    
    static let shared = DataManager()
    fileprivate var persistentContainer: NSPersistentContainer!
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        persistentContainer = NSPersistentContainer(name: "EasyLife")
    }
    
    // MARK: - public
    
    func insert<T:NSManagedObject>(entityClass:T.Type) -> T? {
        let context = mainContext
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            log("couldnt make entityDescription for: \(entityName)")
            let error = NSError(domain: "", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "couldnt make entityDescription for: \(entityName)"
                ])
            Analytics.shared.sendErrorEvent(error, classId: DataManager.self)
            return nil
        }
        return NSManagedObject(entity: entityDescription, insertInto: context) as? T
    }
    
    func delete<T:NSManagedObject>(_ entity:T)  {
        let context = mainContext
        context.delete(entity)
    }
    
    func fetch<T: NSManagedObject>(entityClass:T.Type, sortBy:String? = nil, isAscending:Bool = true, predicate:NSPredicate? = nil, success: @escaping FetchSuccess, failure: Failure? = nil) {
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
