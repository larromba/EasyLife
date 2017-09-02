//
//  ProjectsDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 01/09/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class ProjectsDataSource {
    var dataManager: DataManager
    weak var delegate: TableDataSourceDelegate?
    
    fileprivate let priorityPredicate: NSPredicate
    fileprivate let otherPredicate: NSPredicate
    let maxPriorityItems = 5
    var sections: [[Project]]
    var totalItems: Int {
        return sections.reduce(0, { $0 + $1.count })
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    
    init() {
        dataManager = DataManager.shared
        priorityPredicate = NSPredicate(format: "%K > %d", argumentArray: ["priority", -1])
        otherPredicate = NSPredicate(format: "%K == %d", argumentArray: ["priority", -1])
        sections = [[Project]](repeating: [Project](), count: 2)
    }

    func delete(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        dataManager.delete(item)
        dataManager.save(success: { [weak self] in
            guard let `self` = self else {
                return
            }
            self.sections[indexPath.section].remove(at: indexPath.row)
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func addProject(name: String) {
        guard let project = dataManager.insert(entityClass: Project.self) else {
            return
        }
        project.name = name
        dataManager.save(success: {
            self.load()
        })
    }
    
    func prioritize(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        var available = Set(Array(0..<maxPriorityItems))
        available.subtract(sections[0].map({ Int($0.priority) }))
        let sorted = available.sorted(by: <)
        guard let priority = sorted.first else {
            return
        }
        item.priority = Int16(priority)
        dataManager.save(success: {
            self.load()
        })
    }
    
    func deprioritize(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        item.priority = -1
        dataManager.save(success: {
            self.load()
        })
    }
    
    func move(fromPath: IndexPath, toPath: IndexPath) {
        guard let fromItem = item(at: fromPath), item(at: toPath) != nil else {
            dataManager.save(success: {
                self.delegate?.dataSorceDidLoad(self)
            })
            return
        }
        fromItem.priority = Int16(toPath.row)
        sections[0].remove(at: fromPath.row)
        sections[0].insert(fromItem, at: toPath.row)
        
        if toPath.row < maxPriorityItems {
            move(
                fromPath: IndexPath(row: toPath.row + 1, section: toPath.section),
                toPath: IndexPath(row: toPath.row + 1, section: toPath.section)
            )
        }
    }

    func name(at indexPath: IndexPath) -> String? {
        guard let item = item(at: indexPath) else {
            return nil
        }
        return item.name
    }
    
    func updateName(name: String, at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        item.name = name
        dataManager.save(success: {
            self.delegate?.dataSorceDidLoad(self)
        })
    }
}

// MARK: - TableDataSource

extension ProjectsDataSource: TableDataSource {
    typealias Object = Project
    
    open func load() {
        dataManager.fetch(entityClass: Project.self, sortBy: "priority", isAscending: true, predicate: priorityPredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [Project] else {
                return
            }
            self.sections.replace(items, at: 0)
            self.delegate?.dataSorceDidLoad(self)
        })
        dataManager.fetch(entityClass: Project.self, sortBy: "name", isAscending: true, predicate: otherPredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [Project] else {
                return
            }
            self.sections.replace(items, at: 1)
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func title(for section: Int) -> String? {
        guard section >= 0 && section < sections.count && sections[section].count > 0 else {
            return nil
        }
        switch section {
        case 0:
            return "Priority".localized
        case 1:
            return "Other".localized
        default:
            return nil
        }
    }
    
    func item(at indexPath: IndexPath) -> Project? {
        guard let section = section(at: indexPath.section) else {
            return nil
        }
        guard indexPath.row >= section.startIndex && indexPath.row < section.endIndex else {
            return nil
        }
        let row = section[indexPath.row]
        return row
    }
    
    func section(at index: Int) -> [Project]? {
        guard index >= sections.startIndex && index < sections.endIndex else {
            return nil
        }
        let section = sections[index]
        return section
    }
}
