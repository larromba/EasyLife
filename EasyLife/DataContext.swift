import AsyncAwait
import CoreData
import Foundation
import Logging
import Result

protocol DataContexting {
    func object<T: NSManagedObject>(for object: T) -> T?
    func perform(_ block: @escaping () -> Void)
    func performAndWait(_ block: () -> Void)
    func insert<T: NSManagedObject>(entityClass: T.Type) -> T
    func insertTransient<T: NSManagedObject>(entityClass: T.Type) -> Result<T>
    func copy<T: NSManagedObject>(_ entity: T) -> Result<T>
    func delete<T: NSManagedObject>(_ entity: T)
    func deleteAll(_ objects: [NSManagedObject])
    func deleteAll(_ classTypes: [NSManagedObject.Type]) -> Async<Void>
    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: DataSort<T>?,
                                   predicate: NSPredicate?) -> Async<[T]>
    func save() -> Async<Void>
}

final class DataContext: DataContexting {
    private let managedObjectContext: NSManagedObjectContext
    private let notificationCenter: NotificationCenter

    init(managedObjectContext: NSManagedObjectContext, notificationCenter: NotificationCenter) {
        self.managedObjectContext = managedObjectContext
        self.notificationCenter = notificationCenter
    }

    func object<T: NSManagedObject>(for object: T) -> T? {
        return managedObjectContext.object(with: object.objectID) as? T
    }

    func perform(_ block: @escaping () -> Void) {
        managedObjectContext.perform { block() }
    }

    func performAndWait(_ block: () -> Void) {
        managedObjectContext.performAndWait { block() }
    }

    func insert<T: NSManagedObject>(entityClass: T.Type) -> T {
        return insert(entityName: entityName(entityClass)) as! T
    }

    func insertTransient<T: NSManagedObject>(entityClass: T.Type) -> Result<T> {
        return insertTransient(entityName: entityName(entityClass)).flatMap { .success($0 as! T) }
    }

    // see https://stackoverflow.com/questions/2730832/how-can-i-duplicate-or-copy-a-core-data-managed-object
    func copy<T: NSManagedObject>(_ object: T) -> Result<T> {
        guard let name = object.entity.name else {
            logError(CoreDataError.missingEntitiyName)
            return .failure(CoreDataError.missingEntitiyName)
        }
        let copy = insert(entityClass: T.self)
        let description = NSEntityDescription.entity(forEntityName: name, in: managedObjectContext)
        guard
            let attributess = description?.attributesByName,
            let relationships = description?.relationshipsByName else {
                logError(CoreDataError.entityDescription)
                return .failure(CoreDataError.entityDescription)
        }
        managedObjectContext.performAndWait {
            attributess.forEach { attribute in
                copy.setValue(object.value(forKey: attribute.key), forKey: attribute.key)
            }
            relationships.forEach { (key: String, relationshipDescription: NSRelationshipDescription) in
                if relationshipDescription.isToMany {
                    copy.setValue(object.mutableSetValue(forKey: key), forKey: key)
                } else {
                    copy.setValue(object.value(forKey: key), forKey: key)
                }
            }
        }
        return .success(copy)
    }

    func delete<T: NSManagedObject>(_ entity: T) {
        managedObjectContext.perform { [unowned self] in
            self.managedObjectContext.delete(entity)
        }
    }

    func deleteAll(_ objects: [NSManagedObject]) {
        objects.forEach { delete($0) }
    }

    func deleteAll(_ classTypes: [NSManagedObject.Type]) -> Async<Void> {
        return Async { completion in
            self.managedObjectContext.perform { [unowned self] in
                do {
                    try classTypes.forEach { type in
                        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName(type.self))
                        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
                        try self.managedObjectContext.execute(deleteRequest)
                    }
                    completion(.success(()))
                } catch {
                    completion(.failure(CoreDataError.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                }
            }
        }
    }

    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: DataSort<T>? = nil,
                                   predicate: NSPredicate? = nil) -> Async<[T]> {
        return Async { completion in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName(entityClass))
            request.returnsObjectsAsFaults = false
            request.predicate = predicate
            request.sortDescriptors = sortBy?.sortDescriptor
            self.managedObjectContext.perform { [unowned self] in
                do {
                    var items = try self.managedObjectContext.fetch(request) as! [T]
                    if let sortFunction = sortBy?.sortFunction {
                        items = items.sorted(by: sortFunction)
                    }
                    completion(.success(items))
                } catch {
                    logError(CoreDataError.frameworkError(error))
                    completion(.failure(CoreDataError.frameworkError(error)))
                }
            }
        }
    }

    func save() -> Async<Void> {
        return Async { completion in
            self.managedObjectContext.perform({ [unowned self] in
                guard self.managedObjectContext.hasChanges else {
                    completion(.success(()))
                    return
                }
                do {
                    try self.managedObjectContext.save()
                    completion(.success(()))
                } catch {
                    completion(.failure(CoreDataError.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                }
            })
        }
    }

    // MARK: - private

    private func insert(entityName: String) -> NSManagedObject {
        var object: NSManagedObject!
        managedObjectContext.performAndWait { [unowned self] in
            object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext)
        }
        return object
    }

    private func insertTransient(entityName: String) -> Result<NSManagedObject> {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName,
                                                                 in: managedObjectContext) else {
            logError("couldnt create NSEntityDescription for: \(entityName)")
            return .failure(CoreDataError.entityDescription)
        }
        return .success(NSManagedObject(entity: entityDescription, insertInto: nil))
    }

    private func entityName(_ entityClass: NSManagedObject.Type) -> String {
        guard let name = NSStringFromClass(entityClass).components(separatedBy: ".").last else {
            assertionFailure("unexpected string encountered \(NSStringFromClass(entityClass))")
            return ""
        }
        return name
    }
}
