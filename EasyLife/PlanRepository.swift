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
                    predicate: self.missedPredicate) // use "self.todayPredicate" to check test ui without waiting
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
                ).sorted(by: self.sortByDateAndLaterPriority)
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
                    copy.repeatState = RepeatState.none
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

    private func sortByPriority(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.project != nil && item2.project == nil { return true }
        if item1.project == nil && item2.project != nil { return false }
        if item1.project == nil && item2.project == nil { return sortByName(item1, item2) }
        let defaultPriority = Project.defaultPriority
        if item1.project!.priority != defaultPriority && item2.project!.priority == defaultPriority { return true }
        if item1.project!.priority == defaultPriority && item2.project!.priority != defaultPriority { return false }
        if item1.project!.priority == item2.project!.priority { return sortByName(item1, item2) }
        return item1.project!.priority < item2.project!.priority
    }

    private func sortByName(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.name != nil && item2.name == nil { return true }
        if item1.name == nil && item2.name != nil { return false }
        if item1.name == nil && item2.name == nil { return false }
        if item1.name! == item2.name { return false }
        return item1.name! < item2.name!
    }

    private func sortByDateAndLaterPriority(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.date != nil && item2.date == nil { return false }
        if item1.date == nil && item2.date != nil { return true }
        if item1.date == nil && item2.date == nil { return sortByPriority(item1, item2) }
        if item1.date!.isSameDay(item2.date!) { return sortByPriority(item1, item2) }
        return item1.date! < item2.date!
    }
}

// MARK: - Date

private extension Date {
    func isSameDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let isDayEqual = (calendar.component(.day, from: self) == calendar.component(.day, from: date))
        let isMonthEqual = (calendar.component(.month, from: self) == calendar.component(.month, from: date))
        let isYearEqual = (calendar.component(.year, from: self) == calendar.component(.year, from: date))
        return (isDayEqual && isMonthEqual && isYearEqual)
    }
}
