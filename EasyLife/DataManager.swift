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
    typealias SaveSuccess = (Void) -> Void
    typealias FetchSuccess = ([Any]?) -> Void
    typealias Failure = (Error?) -> Void
    
    static let shared = DataManager()
    fileprivate var persistentContainer: NSPersistentContainer!
    
    init() {
        persistentContainer = NSPersistentContainer(name: "EasyLife")
    }
    
    // MARK: - public
    
    func load(completion: @escaping Failure) {
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            completion(error)
        })
    }
    
    func insert<T:NSManagedObject>(entityClass:T.Type) -> T? {
        let context = persistentContainer.viewContext
        let entityName = NSStringFromClass(entityClass).components(separatedBy: ".").last!
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            return nil
        }
        return NSManagedObject(entity: entityDescription, insertInto: context) as? T
    }
    
    func delete<T:NSManagedObject>(_ entity:T)  {
        let context = persistentContainer.viewContext
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
        
        let context = persistentContainer.viewContext
        context.perform({ [weak context] in
            do {
                let result = try context?.fetch(request)
                DispatchQueue.main.async {
                    success(result)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    failure?(error)
                }
            }
        })
    }
    
    func save(success: SaveSuccess? = nil, failure: Failure? = nil) {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }
        context.perform({ [weak context] in
            do {
                try context?.save()
                success?()
            } catch {
                failure?(error)

                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        })
    }
}
