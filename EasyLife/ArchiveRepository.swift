import AsyncAwait
import CoreData
import Foundation

protocol ArchiveRepositoring {
    func undo(item: TodoItem) -> Async<Void>
    func clearAll(items: [TodoItem]) -> Async<Void>
    func load() -> Async<[Character: [TodoItem]]>
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

    func load() -> Async<[Character: [TodoItem]]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(entityClass: TodoItem.self, sortBy: nil, context: .main,
                                                             predicate: self.donePredicate))
                var sections = [Character: [TodoItem]]()
                for item in items {
                    let section: Character
                    if let name = item.name, !name.isEmpty {
                        section = Character(String(name[name.startIndex]).uppercased())
                    } else {
                        section = Character("-")
                    }
                    var items = sections[section] ?? [TodoItem]()
                    items.append(item)
                    sections[section] = items.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
                }
                completion(.success(sections))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }
}
