import AsyncAwait
import Foundation

protocol BlockedRepositoring {
    func fetchItems(for item: TodoItem) -> Async<[TodoItem]>
}

final class BlockedRepository: BlockedRepositoring {
    private let dataManager: CoreDataManaging

    init(dataManager: CoreDataManaging) {
        self.dataManager = dataManager
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

    // MARK: - private

    // swiftlint:disable line_length
    private func predicate(for item: TodoItem) -> NSPredicate {
        return NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
//        if let item = item {
//
//        } else {
//            return NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0",
//                               argumentArray: ["done", "done", "name", "name.length"])
//        }
    }
}
