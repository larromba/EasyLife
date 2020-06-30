import AsyncAwait
import Foundation
import Logging

// sourcery: name = ItemDetailRepository
protocol ItemDetailRepositoring: Mockable {
    func setContext(_ context: DataContexting)
    func update(_ item: TodoItem, with update: ItemDetailUpdate)
    func fetchItems(for item: TodoItem) -> Async<[TodoItem]>
    func fetchProjects(for item: TodoItem) -> Async<[Project]>
    func save(item: TodoItem) -> Async<Void>
    func delete(item: TodoItem) -> Async<Void>
}

final class ItemDetailRepository: ItemDetailRepositoring {
    private let dataProvider: DataContextProviding
    private var context: DataContexting!

    init(dataProvider: DataContextProviding) {
        self.dataProvider = dataProvider
    }

    func setContext(_ context: DataContexting) {
        self.context = context
    }

    func update(_ item: TodoItem, with update: ItemDetailUpdate) {
        item.name = update.name
        item.notes = update.notes
        item.date = update.date
        item.repeatState = update.repeatState
        item.project = update.project
    }

    func fetchItems(for item: TodoItem) -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let descriptor = NSSortDescriptor(key: "name", ascending: true,
                                                  selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                let items = try await(self.context.fetch(
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
                let descriptor = NSSortDescriptor(key: "name", ascending: true)
                let projects = try await(self.context.fetch(
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
                _ = try await(self.context.save()) // might be child context, so save first
                _ = try await(self.dataProvider.mainContext().save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func delete(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                self.context.delete(item)
                _ = try await(self.save(item: item))
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
