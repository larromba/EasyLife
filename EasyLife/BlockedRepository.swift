import AsyncAwait
import Foundation

// sourcery: name = BlockedByRepository
protocol BlockedByRepositoring: Mockable {
    func setContext(_ context: DataContexting)
    func update(_ item: TodoItem, with update: [BlockingContext<TodoItem>])
    func fetchItems(for item: TodoItem) -> Async<[TodoItem], Error>
}

final class BlockedByRepository: BlockedByRepositoring {
    private var context: DataContexting!

    func setContext(_ context: DataContexting) {
        self.context = context
    }

    func update(_ item: TodoItem, with update: [BlockingContext<TodoItem>]) {
        update.forEach {
            $0.isBlocking ? item.addToBlockedBy($0.object) :  item.removeFromBlockedBy($0.object)
        }
    }

    func fetchItems(for item: TodoItem) -> Async<[TodoItem], Error> {
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

    // MARK: - private

    // swiftlint:disable line_length
    private func predicate(for item: TodoItem) -> NSPredicate {
        return NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
    }
}
