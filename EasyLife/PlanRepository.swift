import AsyncAwait
import CoreData
import Foundation
import Result

// sourcery: name = PlanRepository
protocol PlanRepositoring: Mockable {
    func newItem() -> Result<TodoItem>
    func fetchMissedItems() -> Async<[TodoItem]>
    func fetchLaterItems() -> Async<[TodoItem]>
    func fetchTodayItems() -> Async<[TodoItem]>
    func delete(item: TodoItem) -> Async<Void>
    func later(item: TodoItem) -> Async<Void>
    func done(item: TodoItem) -> Async<Void>
    func split(item: TodoItem) -> Async<Void>
}

final class PlanRepository: PlanRepositoring {
    private let dataManager: CoreDataManaging
    // not lazy as 'today' changes
    private var missedPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K < %@ AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.earliest, "done", "done"])
    }
    private var todayPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K >= %@ AND %K <= %@ AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.earliest, "date", date.latest, "done", "done"])
    }
    private var laterPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "(%K > %@ OR %K = NULL) AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.latest, "date", "done", "done"])
    }
    private var today: Date {
        return Date()
    }

    init(dataManager: CoreDataManaging) {
        self.dataManager = dataManager

        #if DEBUG
        if __isSnapshot {
            do {
                try await(dataManager.reset())
            } catch {
                fatalError(error.localizedDescription)
            }

            let missed1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            missed1.date = Date().addingTimeInterval(-24 * 60 * 60)
            missed1.name = "send letter"

            let now1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            now1.date = Date()
            now1.name = "fix bike"

            let now2 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            now2.date = Date()
            now2.name = "get party food!"

            let later1 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            later1.date = Date().addingTimeInterval(24 * 60 * 60)
            later1.name = "phone mum"

            let later2 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            later2.date = Date().addingTimeInterval(24 * 60 * 60)
            later2.name = "clean flat"

            let later3 = dataManager.insert(entityClass: TodoItem.self, context: .main)
            later3.date = Date().addingTimeInterval(24 * 60 * 60)
            later3.name = "call landlord"

            async({
                _ = try await(dataManager.save(context: .main))
            }, onError: { error in
                fatalError(error.localizedDescription)
            })
        }
        #endif
    }

    func newItem() -> Result<TodoItem> {
        return dataManager.insertTransient(entityClass: TodoItem.self, context: .main)
    }

    func fetchMissedItems() -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(
                    entityClass: TodoItem.self,
                    sortBy: nil, context: .main,
                    predicate: self.missedPredicate)
                ).sorted(by: self.sortByPriority)
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchLaterItems() -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(
                    entityClass: TodoItem.self,
                    sortBy: nil, context: .main,
                    predicate: self.laterPredicate)
                ).sorted(by: self.sortByDateAndPriority)
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchTodayItems() -> Async<[TodoItem]> {
        return Async { completion in
            async({
                let items = try await(self.dataManager.fetch(
                    entityClass: TodoItem.self,
                    sortBy: nil, context: .main,
                    predicate: self.todayPredicate)
                    ).sorted(by: self.sortByPriority)
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
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

    func later(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                switch item.repeatState! {
                case .none:
                    item.date = nil
                default:
                    item.incrementDate()
                }
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func done(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                switch item.repeatState! {
                case .none:
                    item.done = true
                default:
                    item.incrementDate()
                }
                item.blocking = nil
                _ = try await(self.dataManager.save(context: .main))
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func split(item: TodoItem) -> Async<Void> {
        return Async { completion in
            async({
                guard item.repeatState != .none else { return }
                let result = self.dataManager.copy(item, context: .main)
                switch result {
                case .success(let copy):
                    item.incrementDate()
                    item.blockedBy = nil
                    copy.repeatState = .none
                    _ = try await(self.dataManager.save(context: .main))
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    // MARK: - private

    // @note coredata sorts are a bit shit, so need to do it here for advanced sorting
    private func sortByPriority(item1: TodoItem, item2: TodoItem) -> Bool {
        let priority1 = item1.project?.priority ?? Project.defaultPriority
        let priority2 = item2.project?.priority ?? Project.defaultPriority
        if priority1 == Project.defaultPriority { return false }
        if priority2 == Project.defaultPriority { return true }
        return priority1 < priority2
    }

    private func sortByDateAndPriority(item1: TodoItem, item2: TodoItem) -> Bool {
        if item1.date == nil && item2.date == nil { return sortByPriority(item1: item1, item2: item2) }
        guard let date1 = item1.date else { return true }
        guard let date2 = item2.date else { return false }
        if date1.day == date2.day { return sortByPriority(item1: item1, item2: item2) }
        return date1 < date2
    }
}

// MARK: - Date

private extension Date {
    var day: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }
}
