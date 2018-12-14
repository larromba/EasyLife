import Foundation

protocol ItemDetailDelegate: AnyObject {
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedName name: String?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedNotes notes: String?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedDate date: String?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedRepeatState state: RepeatState?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedProject project: Project?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedProjects projects: [Project]?)
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedBlockable blockable: [BlockedItem]?)
    func itemDetailDataSourceDidDelete(_ delegate: ItemDetailDataSource)
    func itemDetailDataSourceDidSave(_ delegate: ItemDetailDataSource)
}

class ItemDetailDataSource {
    weak var delegate: ItemDetailDelegate?
    var dataManager: DataManager
    var item: TodoItem? {
        didSet {
            canSave = false
        }
    }
    var dateFormatter: DateFormatter
    var now: Date
    var name: String? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedName: name)
        }
    }
    var notes: String? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedNotes: notes)
        }
    }
    var date: Date? {
        didSet {
            if let date = date {
                self.delegate?.itemDetailDataSource(self, updatedDate: dateFormatter.string(from: date))
            } else {
                self.delegate?.itemDetailDataSource(self, updatedDate: nil)
            }
        }
    }
    var repeatState: RepeatState? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedRepeatState: repeatState)
        }
    }
    var project: Project? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedProject: project)
        }
    }
    var projects: [Project]? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedProjects: projects)
        }
    }
    var repeatStateData: [RepeatState]
    var blockable: [BlockedItem]? {
        didSet {
            self.delegate?.itemDetailDataSource(self, updatedBlockable: blockable)
        }
    }
    private(set) var canSave: Bool
    fileprivate var loaded: Bool

    init() {
        dataManager = DataManager.shared
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        now = Date()
        repeatStateData = RepeatState.display
        canSave = true
        loaded = false
    }

    // swiftlint:disable line_length
    func load() {
        guard !loaded else {
            return
        }
        loaded = true

        let predicate: NSPredicate
        if let item = item {
            predicate = NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0 AND SELF != %@ AND SUBQUERY(%K, $x, $x == %@).@count == 0", argumentArray: ["done", "done", "name", "name.length", item.objectID, "blockedBy", item.objectID])
        } else {
            predicate = NSPredicate(format: "(%K = NULL OR %K = false) AND %K != NULL AND %K > 0", argumentArray: ["done", "done", "name", "name.length"])
        }
        dataManager.fetch(entityClass: TodoItem.self, sortBy: [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))], context: dataManager.mainContext, predicate: predicate, success: { [weak self] results in
            guard let `self` = self, let results = results as? [TodoItem] else {
                return
            }
            if let item = self.item {
                self.blockable = results.map({ return BlockedItem(item: $0, isBlocked: ($0.blocking?.contains(item) ?? false)) })
            } else {
                self.blockable = results.map({ return BlockedItem(item: $0, isBlocked: false) })
            }
        })
        dataManager.fetch(entityClass: Project.self, sortBy: [NSSortDescriptor(key: "name", ascending: true)], context: dataManager.mainContext, success: { [weak self] results in
            guard let `self` = self, let results = results as? [Project] else {
                return
            }
            self.projects = results
        })
        name = item?.name
        notes = item?.notes
        date = item?.date as Date?
        repeatState = item?.repeatState
        project = item?.project
    }

    func save() {
        guard let item = self.item else {
            return
        }
        item.name = name
        item.notes = notes
        item.date = date
        item.repeatState = repeatState
        item.project = project

        blockable?.forEach({ blockedItem in
            if blockedItem.isBlocked {
                item.addToBlockedBy(blockedItem.item)
            } else {
                item.removeFromBlockedBy(blockedItem.item)
            }
        })
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.itemDetailDataSourceDidSave(self)
        })
    }

    func create() {
        item = dataManager.insert(entityClass: TodoItem.self, context: dataManager.mainContext)
    }

    func delete() {
        guard let item = item else {
            return
        }
        dataManager.delete(item, context: dataManager.mainContext)
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.delegate?.itemDetailDataSourceDidDelete(self)
        })
        self.item = nil
    }
}
