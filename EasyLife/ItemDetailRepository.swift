import AsyncAwait
import Foundation
import Logging

protocol ItemDetailRepositoring: Mockable {
    func fetchItems(for item: TodoItem) -> Async<[TodoItem]>
    func fetchProjects(for item: TodoItem) -> Async<[Project]>
    func save(item: TodoItem) -> Async<Void>
    func delete(item: TodoItem) -> Async<Void>
}

final class ItemDetailRepository: ItemDetailRepositoring {
    private let dataManager: CoreDataManaging
    private let now: Date

    init(dataManager: CoreDataManaging, now: Date) {
        self.dataManager = dataManager
        self.now = now
    }

    func fetchItems(for item: TodoItem) -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(
                    entityClass: TodoItem.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true,
                                              selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))],
                    context: .main,
                    predicate: self.predicate(for: item)
                ))
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchProjects(for item: TodoItem) -> Async<[Project]> {
        return Async { completion in
            async({
                let projects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true)],
                    context: .main,
                    predicate: nil
                ))
                completion(.success(projects))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func save(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                if item.managedObjectContext == nil {
                    switch self.dataManager.copy(item, context: .main) {
                    case .success:
                        break
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    }
                }
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func delete(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                self.dataManager.delete(item, context: .main)
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    // MARK: - private

    // swiftlint:disable line_length
    private func predicate(for item: TodoItem) -> NSPredicate {
        return NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
    }
}
