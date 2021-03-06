import AsyncAwait
import CoreData
import Foundation

// sourcery: name = ArchiveRepository
protocol ArchiveRepositoring: Mockable {
    func undo(item: TodoItem) -> Async<Void, Error>
    func clearAll(items: [TodoItem]) -> Async<Void, Error>
    func fetchItems() -> Async<[TodoItem], Error>
}

final class ArchiveRepository: ArchiveRepositoring {
    private let dataContextProvider: DataContextProviding
    private let donePredicate = NSPredicate(format: "%K = true", argumentArray: ["done"])

    init(dataContextProvider: DataContextProviding) {
        self.dataContextProvider = dataContextProvider
    }

    func undo(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    item.done = false
                    item.date = nil
                    item.repeatState = .default
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func clearAll(items: [TodoItem]) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
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

    func fetchItems() -> Async<[TodoItem], Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
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
