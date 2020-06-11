import AsyncAwait
import Foundation
import Logging

// sourcery: name = ItemDetailRepository
protocol ItemDetailRepositoring: Mockable {
    func setChildContext(_ childContext: DataContexting)
    func fetchItems(for item: TodoItem) -> Async<[TodoItem]>
    func fetchProjects(for item: TodoItem) -> Async<[Project]>
    func save(item: TodoItem) -> Async<Void>
    func delete(item: TodoItem) -> Async<Void>
}

final class ItemDetailRepository: ItemDetailRepositoring {
    private let dataProvider: DataContextProviding
    private let now: Date
    private var childContext: DataContexting?

    init(dataProvider: DataContextProviding, now: Date) {
        self.dataProvider = dataProvider
        self.now = now
    }

    func setChildContext(_ childContext: DataContexting) {
        self.childContext = childContext
    }

    func fetchItems(for item: TodoItem) -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let context = self.dataProvider.mainContext()
                let descriptor = NSSortDescriptor(key: "name", ascending: true,
                                                  selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                let items = try await(context.fetch(
                    entityClass: TodoItem.self,
                    sortBy: DataSort(sortDescriptor: [descriptor]),
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
                let context = self.dataProvider.mainContext()
                let descriptor = NSSortDescriptor(key: "name", ascending: true)
                let projects = try await(context.fetch(
                    entityClass: Project.self,
                    sortBy: DataSort(sortDescriptor: [descriptor]),
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
                if let childContext = self.childContext {
                    _ = try await(childContext.save())
                }
                let mainContext = self.dataProvider.mainContext()
                _ = try await(mainContext.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func delete(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                let context = self.dataProvider.mainContext()
                context.delete(item)
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    // swiftlint:disable line_length
    private func predicate(for item: TodoItem) -> NSPredicate {
        return NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
    }
}
