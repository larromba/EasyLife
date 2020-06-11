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
    private let dataManager: DataManaging
    private let donePredicate = NSPredicate(format: "%K = true", argumentArray: ["done"])

    init(dataManager: DataManaging) {
        self.dataManager = dataManager
    }

    func undo(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataManager.mainContext()
                context.performAndWait {
                    item.done = false
                    item.date = nil
                    item.repeatState = RepeatState.none
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func clearAll(items: [TodoItem]) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataManager.mainContext()
                items.forEach { item in
                    context.delete(item)
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchItems() -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let context = self.dataManager.mainContext()
                let items = try await(context.fetch(
                    entityClass: TodoItem.self,
                    sortBy: nil,
                    predicate: self.donePredicate)
                )
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
