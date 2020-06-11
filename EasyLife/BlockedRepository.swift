import AsyncAwait
import Foundation

// sourcery: name = BlockedByRepository
protocol BlockedByRepositoring: Mockable {
    func fetchItems(for item: TodoItem) -> Async<[TodoItem]>
}

final class BlockedByRepository: BlockedByRepositoring {
    private let dataProvider: DataContextProviding

    init(dataProvider: DataContextProviding) {
        self.dataProvider = dataProvider
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
