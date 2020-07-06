import AsyncAwait
import Foundation

// sourcery: name = FocusRepository
protocol FocusRepositoring: Mockable {
    func fetchItems() -> Async<[TodoItem], Error>
    func fetchMissingItems() -> Async<[TodoItem], Error>
    func isDoable() -> Async<Bool, Error>
    func today(item: TodoItem) -> Async<Void, Error>
    func done(item: TodoItem) -> Async<Void, Error>
}

final class FocusRepository: FocusRepositoring {
    private let dataContextProvider: DataContextProviding
    private let planRepository: PlanRepositoring

    init(dataContextProvider: DataContextProviding, planRepository: PlanRepositoring) {
        self.dataContextProvider = dataContextProvider
        self.planRepository = planRepository
    }

    func fetchItems() -> Async<[TodoItem], Error> {
        return planRepository.fetchTodayItems()
    }

    func fetchMissingItems() -> Async<[TodoItem], Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let items = try await(self.planRepository.fetchTodayItems())
                var missingItems: [TodoItem]!
                context.performAndWait {
                    let blockedByItems = Set(items.compactMap { $0.blockedBy as? Set<TodoItem> }.reduce([], +))
                    missingItems = Array(blockedByItems.subtracting(items))
                }
                completion(.success(missingItems))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func isDoable() -> Async<Bool, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let items = try await(self.planRepository.fetchTodayItems())
                var isDoable: Bool!
                context.performAndWait {
                    isDoable = (items.first?.blockedBy?.count ?? 0 == 0)
                }
                completion(.success(isDoable))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func today(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    item.date = Date()
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func done(item: TodoItem) -> Async<Void, Error> {
        return planRepository.done(item: item)
    }
}
