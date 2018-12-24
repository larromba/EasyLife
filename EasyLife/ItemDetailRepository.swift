import AsyncAwait
import Foundation

protocol ItemDetailRepositoring {
    func load(for item: TodoItem) -> Async<[ItemDetailComponent: [AnyComponentItem<Any>]]>
    func load() -> Async<[ItemDetailComponent: [AnyComponentItem<Any>]]>
    func save() -> Async<Void>
    func newItem() -> TodoItem
    func delete(item: TodoItem) -> Async<Void>
}

final class ItemDetailRepository: ItemDetailRepositoring {
    private let dataManager: CoreDataManaging
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        return dateFormatter
    }()
    private let now: Date

    init(dataManager: CoreDataManaging, now: Date) {
        self.dataManager = dataManager
        self.now = now
    }

    // swiftlint:disable line_length
    func load() -> Async<[ItemDetailComponent: [AnyComponentItem<Any>]]> {
        let predicate = NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0",
                                    argumentArray: ["done", "done", "name", "name.length"])
        return load(predicate: predicate)
    }

    func load(for item: TodoItem) -> Async<[ItemDetailComponent: [AnyComponentItem<Any>]]> {
        let predicate = NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
        return load(predicate: predicate)
    }

    func save() -> Async<Void> {
        return Async { completion in
            async({
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func newItem() -> TodoItem {
        return dataManager.insert(entityClass: TodoItem.self, context: .main)
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

    private func load(predicate: NSPredicate) -> Async<[ItemDetailComponent: [AnyComponentItem<Any>]]> {
        return Async { callback in
            async({
                let items = try await(self.dataManager.fetch(
                    entityClass: TodoItem.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true,
                                              selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))],
                    context: .main,
                    predicate: predicate
                ))
                let projects = try await(self.dataManager.fetch(
                    entityClass: Project.self,
                    sortBy: [NSSortDescriptor(key: "name", ascending: true)],
                    context: .main,
                    predicate: predicate
                ))
                let repatStateItems = items.map {
                    AnyComponentItem(RepeatStateComponentItem(object: $0.repeatState!))
                } // TODO: !
                let projectItems = projects.map { AnyComponentItem(ProjectComponentItem(object: $0)) }

                // TODO: this shit
//                callback(.success([
//                    .repeatState: repatStateItems,
//                    .projects: projectItems
//                    ])
            }, onError: { error in
                callback(.failure(error))
            })
        }

        /*
         if let item = self.item {
         self.blockable = results.map({ return BlockedItem(item: $0, isBlocked: ($0.blocking?.contains(item) ?? false)) })
         } else {
         self.blockable = results.map({ return BlockedItem(item: $0, isBlocked: false) })
         }

         name = item?.name
         notes = item?.notes
         date = item?.date as Date?
         repeatState = item?.repeatState
         project = item?.project
         */

    }
}
