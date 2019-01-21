import AsyncAwait
import CoreData
import Foundation

// sourcery: name = ArchiveRepository
protocol ArchiveRepositoring: Mockable {
    func undo(item: TodoItem) -> Async<Void>
    func clearAll(items: [TodoItem]) -> Async<Void>
    func fetchItems() -> Async<[TodoItem]>
}

final class ArchiveRepository: ArchiveRepositoring {
    private let dataManager: CoreDataManaging
    private let donePredicate = NSPredicate(format: "%K = true", argumentArray: ["done"])

    init(dataManager: CoreDataManaging) {
        self.dataManager = dataManager
    }

    func undo(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                item.done = false
                item.date = nil
                item.repeatState = RepeatState.none
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func clearAll(items: [TodoItem]) -> Async<Void> {
        return Async { completion in
            async({
                items.forEach { item in
                    self.dataManager.delete(item, context: .main)
                }
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchItems() -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil, context: .main,
                                                             predicate: self.donePredicate))
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
