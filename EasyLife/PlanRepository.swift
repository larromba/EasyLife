import AsyncAwait
import CoreData
import Foundation

// sourcery: name = PlanRepository
protocol PlanRepositoring: Mockable {
    func newItemContext() -> TodoItemContext
    func existingItemContext(item: TodoItem) -> TodoItemContext
    func makeToday(item: TodoItem) -> Async<Void, Error>
    func makeTomorrow(item: TodoItem) -> Async<Void, Error>
    func makeAllToday(items: [TodoItem]) -> Async<Void, Error>
    func makeAllTomorrow(items: [TodoItem]) -> Async<Void, Error>
    func fetchMissedItems() -> Async<[TodoItem], Error>
    func fetchLaterItems() -> Async<[TodoItem], Error>
    func fetchTodayItems() -> Async<[TodoItem], Error>
    func delete(item: TodoItem) -> Async<Void, Error>
    func later(item: TodoItem) -> Async<Void, Error>
    func done(item: TodoItem) -> Async<Void, Error>
    func split(item: TodoItem) -> Async<Void, Error>
}

final class PlanRepository: PlanRepositoring {
    private let dataContextProvider: DataContextProviding
    // predicates not lazy as 'today' changes
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

    init(dataContextProvider: DataContextProviding) {
        self.dataContextProvider = dataContextProvider
    }

    func newItemContext() -> TodoItemContext {
        let context = dataContextProvider.childContext(thread: .main)
        let item = context.insert(entityClass: TodoItem.self)
        return .new(item: item, context: context)
    }

    func existingItemContext(item: TodoItem) -> TodoItemContext {
        let context = dataContextProvider.mainContext()
        return .existing(item: item, context: context)
    }

    func makeToday(item: TodoItem) -> Async<Void, Error> {
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

    func makeTomorrow(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    item.date = Date().addingTimeInterval(24 * 60 * 60)
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func makeAllToday(items: [TodoItem]) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    items.forEach { $0.date = Date() }
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func makeAllTomorrow(items: [TodoItem]) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    items.forEach { $0.date = Date().addingTimeInterval(24 * 60 * 60) }
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchMissedItems() -> Async<[TodoItem], Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let items = try await(context.fetch(
                    entityClass: TodoItem.self,
                    sortBy: DataSort(sortFunction: self.sortByPriority),
                    predicate: self.missedPredicate)) // use "self.todayPredicate" to check test ui without waiting
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchLaterItems() -> Async<[TodoItem], Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let items = try await(context.fetch(
                    entityClass: TodoItem.self,
                    sortBy: DataSort(sortFunction: self.sortByDate),
                    predicate: self.laterPredicate))
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func fetchTodayItems() -> Async<[TodoItem], Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                let items = try await(context.fetch(
                    entityClass: TodoItem.self,
                    sortBy: DataSort(sortFunction: self.sortByPriority),
                    predicate: self.todayPredicate))
                completion(.success(items))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func delete(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.delete(item)
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func later(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    switch item.repeatState {
                    case .none:
                        item.date = nil
                    default:
                        item.incrementDate()
                    }
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func done(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                context.performAndWait {
                    switch item.repeatState {
                    case .none:
                        item.done = true
                    default:
                        item.incrementDate()
                    }
                    item.blocking = nil
                }
                _ = try await(context.save())
                completion(.success(()))
            }, onError: { error in
                completion(.failure(error))
            })
        }
    }

    func split(item: TodoItem) -> Async<Void, Error> {
        return Async { completion in
            async({
                let context = self.dataContextProvider.mainContext()
                var isValid: Bool!
                context.performAndWait {
                    isValid = (item.repeatState != .default)
                }
                guard isValid else { return }
                let result = context.copy(item)
                switch result {
                case .success(let copy):
                    context.performAndWait {
                        item.incrementDate()
                        item.blockedBy = nil
                        copy.repeatState = .default
                    }
                    _ = try await(context.save())
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
    // @note coredata sorts are are limited, so need to do it here for advanced sorting
    // 1. date (<)
    // 2. priority (<)
    // 3. blocking (<) [none, blocking, both, blockedBy]
    // 4. name (<)

    private func sortByDate(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.date != nil && item2.date == nil { return false }
        if item1.date == nil && item2.date != nil { return true }
        if item1.date == nil && item2.date == nil { return sortByPriority(item1, item2) }
        if item1.date!.isSameDay(item2.date!) { return sortByPriority(item1, item2) }
        return item1.date! < item2.date!
    }

    private func sortByPriority(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.project != nil && item2.project == nil { return true }
        if item1.project == nil && item2.project != nil { return false }
        if item1.project == nil && item2.project == nil { return sortByBlocking(item1, item2) }
        let defaultPriority = Project.defaultPriority
        if item1.project!.priority != defaultPriority && item2.project!.priority == defaultPriority { return true }
        if item1.project!.priority == defaultPriority && item2.project!.priority != defaultPriority { return false }
        if item1.project!.priority == item2.project!.priority { return sortByBlocking(item1, item2) }
        return item1.project!.priority < item2.project!.priority
    }

    private func sortByBlocking(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.blockingState == .none && item2.blockingState != .none { return true }
        if item1.blockingState != .none && item2.blockingState == .none { return false }
        if item1.blockingState == .blocking && item2.blockingState != .blocking { return true }
        if item1.blockingState != .blocking && item2.blockingState == .blocking { return false }
        if item1.blockingState == .both && item2.blockingState != .both { return true }
        if item1.blockingState != .both && item2.blockingState == .both { return false }
        if item1.blockingState == .blockedBy && item2.blockingState != .blockedBy { return true }
        if item1.blockingState != .blockedBy && item2.blockingState == .blockedBy { return false }
        return sortByName(item1, item2)
    }

    private func sortByName(_ item1: TodoItem, _ item2: TodoItem) -> Bool {
        if item1.name != nil && item2.name == nil { return true }
        if item1.name == nil && item2.name != nil { return false }
        if item1.name == nil && item2.name == nil { return false }
        if item1.name! == item2.name! { return false }
        return item1.name! < item2.name!
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

// MARK: - TodoItem

private extension TodoItem {
    enum BlockingState {
        case none
        case blocking
        case both
        case blockedBy
    }

    var isBlocking: Bool {
        return (blocking?.count ?? 0) > 0
    }
    var isBlockedBy: Bool {
        return (blockedBy?.count ?? 0) > 0
    }
    var blockingState: BlockingState {
        if !isBlocking && !isBlockedBy { return .none }
        if isBlocking && !isBlockedBy { return .blocking }
        if isBlocking && isBlockedBy { return .both }
        return .blockedBy
    }
}
