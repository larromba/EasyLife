import CoreData
import Foundation

class PlanDataSource: NSObject { // NSObject needed to override extensions in unit test
    var dataManager: DataManager
    var sections: [[TodoItem]]
    weak var delegate: TableDataSourceDelegate?

    // not lazy var as 'today' changes
    fileprivate var missedPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K < %@ AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.earliest, "done", "done"])
    }
    fileprivate var todayPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K >= %@ AND %K <= %@ AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.earliest, "date", date.latest, "done", "done"])
    }
    fileprivate var laterPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "(%K > %@ OR %K = NULL) AND (%K = NULL OR %K = false)",
                           argumentArray: ["date", date.latest, "date", "done", "done"])
    }
    var today: Date {
        return Date()
    }
    var total: Int {
        return sections.reduce(0) { $0 + $1.count }
    }
    var totalMissed: Int {
        return sections[0].count
    }
    var totalToday: Int {
        return sections[1].count
    }
    var totalLater: Int {
        return sections[2].count
    }
    var isDoneTotally: Bool {
        return total == 0
    }
    var isDoneForNow: Bool {
        return totalMissed == 0 && totalToday == 0
    }

    override init() {
        dataManager = DataManager.shared
        sections = [[TodoItem]](repeating: [TodoItem](), count: 3)
        super.init()
    }

    // MARK: - public

#if DEBUG
    func itunesConnect() {
        let missed1 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        missed1.date = Date().addingTimeInterval(-24 * 60 * 60)
        missed1.name = "send letter"

        let now1 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        now1.date = Date()
        now1.name = "fix bike"

        let now2 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        now2.date = Date()
        now2.name = "get party food!"

        let later1 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        later1.date = Date().addingTimeInterval(24 * 60 * 60)
        later1.name = "phone mum"

        let later2 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        later2.date = Date().addingTimeInterval(24 * 60 * 60)
        later2.name = "clean flat"

        let later3 = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)!
        later3.date = Date().addingTimeInterval(24 * 60 * 60)
        later3.name = "call landlord"

        dataManager.save(context: dataManager.mainContext)
    }
#endif

    func delete(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        dataManager.delete(item, context: dataManager.mainContext)
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            self?.load()
        })
    }

    func later(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        switch item.repeatState! {
        case .none:
            item.date = nil
        default:
            item.incrementDate()
        }
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            self?.load()
        })
    }

    func done(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        switch item.repeatState! {
        case .none:
            item.done = true
        default:
            item.incrementDate()
        }
        item.blocking = nil
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            self?.load()
        })
    }

    func split(at indexPath: IndexPath) {
        guard let item = item(at: indexPath), item.repeatState != .none else {
            return
        }
        guard let copy = dataManager.copy(item, context: dataManager.mainContext) as? TodoItem else {
            return
        }
        item.incrementDate()
        item.blockedBy = nil
        copy.repeatState = .none
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            self?.load()
        })
    }

    // MARK: - private

    // @note coredata sorts are a bit shit, so need to do it here for advanced sorting
    fileprivate func sortByPriority(item1: TodoItem, item2: TodoItem) -> Bool {
        let priority1 = item1.project?.priority ?? Project.defaultPriority
        let priority2 = item2.project?.priority ?? Project.defaultPriority
        if priority1 == Project.defaultPriority { return false }
        if priority2 == Project.defaultPriority { return true }
        return priority1 < priority2
    }

    fileprivate func sortByDateAndPriority(item1: TodoItem, item2: TodoItem) -> Bool {
        if item1.date == nil && item2.date == nil { return sortByPriority(item1: item1, item2: item2) }
        guard let date1 = item1.date else { return true }
        guard let date2 = item2.date else { return false }
        if date1.day == date2.day { return sortByPriority(item1: item1, item2: item2) }
        return date1 < date2
    }
}

// MARK: - TableDataSource

extension PlanDataSource: TableDataSource {
    typealias Object = TodoItem

    func load() {
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, predicate: missedPredicate,
                          success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items.sorted(by: self.sortByPriority), at: 0)
            self.delegate?.dataSorceDidLoad(self)
        })
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, predicate: todayPredicate,
                          success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items.sorted(by: self.sortByPriority), at: 1)
            self.delegate?.dataSorceDidLoad(self)
        })
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, predicate: laterPredicate,
                          success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items.sorted(by: self.sortByDateAndPriority), at: 2)
            self.delegate?.dataSorceDidLoad(self)
        })
    }

    func title(for section: Int) -> String? {
        guard section >= 0 && section < sections.count && !sections[section].isEmpty else {
            return nil
        }
        switch section {
        case 0:
            return L10n.missedSection
        case 1:
            return L10n.todaySection
        case 2:
            return L10n.laterSection
        default:
            return nil
        }
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        guard let section = section(at: indexPath.section) else {
            return nil
        }
        guard indexPath.row >= section.startIndex && indexPath.row < section.endIndex else {
            return nil
        }
        let row = section[indexPath.row]
        return row
    }

    func section(at index: Int) -> [TodoItem]? {
        guard index >= sections.startIndex && index < sections.endIndex else {
            return nil
        }
        let section = sections[index]
        return section
    }
}

// MARK: - Date

private extension Date {
    var day: Int {
        let calendar = Calendar.current
        return calendar.component(.day, from: self)
    }
}
