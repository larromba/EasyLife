import AsyncAwait
import CoreData
import Foundation
import Logging
import Result

protocol CoreDataManaging: AnyObject {
    var isLoaded: Bool { get }

    func insert<T: NSManagedObject>(entityClass: T.Type, context: CoreDataContext) -> T
    func insertTransient<T: NSManagedObject>(entityClass: T.Type, context: CoreDataContext) -> Result<T>
    func copy<T: NSManagedObject>(_ entity: T, context: CoreDataContext) -> Result<T>
    func delete<T: NSManagedObject>(_ entity: T, context: CoreDataContext)
    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: [NSSortDescriptor]?, context: CoreDataContext,
                                   predicate: NSPredicate?) -> Async<[T]>
    func load() -> Async<Void>
    func save(context: CoreDataContext) -> Async<Void>
}

final class CoreDataManager: CoreDataManaging {
    private let persistentContainer: NSPersistentContainer
    private let notificationCenter: NotificationCenter
    private var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    private var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    var isLoaded: Bool = false

    init(persistentContainer: NSPersistentContainer, notificationCenter: NotificationCenter = .default) {
        self.persistentContainer = persistentContainer
        self.notificationCenter = notificationCenter
    }

    func insert<T: NSManagedObject>(entityClass: T.Type, context: CoreDataContext) -> T {
        return insert(entityName: entityName(entityClass), context: context) as! T
    }

    func insertTransient<T: NSManagedObject>(entityClass: T.Type, context: CoreDataContext) -> Result<T> {
        return insertTransient(entityName: entityName(entityClass), context: context).flatMap { .success($0 as! T) }
    }

    // see https://stackoverflow.com/questions/2730832/how-can-i-duplicate-or-copy-a-core-data-managed-object
    func copy<T: NSManagedObject>(_ entity: T, context: CoreDataContext) -> Result<T> {
        guard self.isLoaded else {
            return .failure(CoreDataError.notLoaded)
        }
        guard let name = entity.entity.name else {
            return .failure(CoreDataError.missingEntitiyName)
        }
        guard let copy = insert(entityName: name, context: context) as? T else { // TODO: way around this cast?
            return .failure(CoreDataError.copy)
        }
        let description = NSEntityDescription.entity(forEntityName: name, in: managedObjectContext(for: context))
        guard
            let attributess = description?.attributesByName,
            let relationships = description?.relationshipsByName else {
                return .failure(CoreDataError.entityDescription)
        }
        attributess.forEach { attribute in
            copy.setValue(entity.value(forKey: attribute.key), forKey: attribute.key)
        }
        relationships.forEach { (key: String, desc: NSRelationshipDescription) in
            if desc.isToMany {
                copy.setValue(entity.mutableSetValue(forKey: key), forKey: key)
            } else {
                copy.setValue(entity.value(forKey: key), forKey: key)
            }
        }
        return .success(copy)
    }

    func delete<T: NSManagedObject>(_ entity: T, context: CoreDataContext) {
        guard self.isLoaded else {
            logError(CoreDataError.notLoaded)
            return
        }
        managedObjectContext(for: context).delete(entity)
    }

    func fetch<T: NSManagedObject>(entityClass: T.Type, sortBy: [NSSortDescriptor]? = nil,
                                   context: CoreDataContext, predicate: NSPredicate? = nil) -> Async<[T]> {
        return Async { completion in
            guard self.isLoaded else {
                return completion(.failure(CoreDataError.notLoaded))
            }
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: self.entityName(entityClass))
            request.returnsObjectsAsFaults = false
            request.predicate = predicate
            request.sortDescriptors = sortBy
            let context = self.managedObjectContext(for: context)
            context.perform({ [unowned context] in
                do {
                    completion(.success(try context.fetch(request) as! [T]))
                } catch {
                    completion(.failure(CoreDataError.frameworkError(error)))
                }
            })
        }
    }

    func load() -> Async<Void> {
        return Async { completion in
            self.persistentContainer.loadPersistentStores(completionHandler: { _, error in
                if let error = error {
                    completion(.failure(CoreDataError.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                    return
                }
                self.isLoaded = true
                completion(.success(()))
            })
        }
    }

    func save(context: CoreDataContext) -> Async<Void> {
        return Async { completion in
            guard self.isLoaded else {
                return completion(.failure(CoreDataError.notLoaded))
            }
            let context = self.managedObjectContext(for: context)
            guard context.hasChanges else {
                completion(.success(()))
                return
            }
            context.perform({ [unowned context] in
                do {
                    try context.save()
                    completion(.success(()))
                } catch {
                    completion(.failure(CoreDataError.frameworkError(error)))
                    self.notificationCenter.post(name: .applicationDidReceiveFatalError, object: error)
                }
            })
        }
    }

    // MARK: - private

    private func insert(entityName: String, context: CoreDataContext) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext(for: context))
    }

    private func insertTransient(entityName: String, context: CoreDataContext) -> Result<NSManagedObject> {
        let context = self.managedObjectContext(for: context)
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            logError("couldnt create NSEntityDescription for: \(entityName)")
            return .failure(CoreDataError.entityDescription)
        }
        return .success(NSManagedObject(entity: entityDescription, insertInto: nil))
    }

    private func managedObjectContext(for context: CoreDataContext) -> NSManagedObjectContext {
        switch context {
        case .main:
            return mainContext
        case .background:
            return backgroundContext
        }
    }

    private func entityName<T: NSManagedObject>(_ entityClass: T.Type) -> String {
        guard let name = NSStringFromClass(entityClass).components(separatedBy: ".").last else {
            fatalError("unexpected state from NSStringFromClass")
        }
        return name
    }
}
