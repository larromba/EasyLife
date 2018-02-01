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
    let deprioritizedValue = -1
    var sections: [[Project]]
    var totalItems: Int {
        return sections.reduce(0, { $0 + $1.count })
    }
    var totalPriorityItems: Int {
        return sections[0].count
    }
    var totalNonPriorityItems: Int {
        return sections[1].count
    }
    var isMaxPriorityItemLimitReached: Bool {
        return totalPriorityItems >= maxPriorityItems
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    
    init() {
        dataManager = DataManager.shared
        priorityPredicate = NSPredicate(format: "%K > %d", argumentArray: ["priority", deprioritizedValue])
        otherPredicate = NSPredicate(format: "%K == %d", argumentArray: ["priority", deprioritizedValue])
        sections = [[Project]](repeating: [Project](), count: 2)
    }

    func delete(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        dataManager.delete(item)
        sections[indexPath.section].remove(at: indexPath.row)
        if indexPath.section == 0 {
            flushPriority()
        }
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func addProject(name: String) {
        guard let project = dataManager.insert(entityClass: Project.self) else {
            return
        }
        project.name = name
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func prioritize(at indexPath: IndexPath) {
        guard totalPriorityItems < maxPriorityItems, indexPath.section == 1, let item = item(at: indexPath) else {
            return
        }
        var available = Set(Array(0..<maxPriorityItems))
        available.subtract(sections[0].map({ Int($0.priority) }))
        let sorted = available.sorted(by: <)
        guard let nextAvailablePriority = sorted.first else {
            return
        }
        item.priority = Int16(nextAvailablePriority)
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func deprioritize(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        item.priority = Int16(deprioritizedValue)
        sections[indexPath.section].remove(at: indexPath.row)
        flushPriority()
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func move(fromPath: IndexPath, toPath: IndexPath) {
        guard let fromItem = item(at: fromPath) else {
            return
        }
        sections[fromPath.section].remove(at: fromPath.row)
        sections[toPath.section].insert(fromItem, at: toPath.row)

        flushPriority()
        flushNonPriority()

        dataManager.save(success: { [weak self] in
            self?.load()
        })
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
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }

    // MARK: - private

    func flushPriority() {
        for i in 0..<totalPriorityItems {
            let itemPath = IndexPath(row: i, section:0)
            if let item = self.item(at: itemPath) {
                item.priority = Int16(i)
            }
        }
    }

    func flushNonPriority() {
        for i in 0..<totalNonPriorityItems {
            let itemPath = IndexPath(row: i, section:1)
            if let item = self.item(at: itemPath) {
                item.priority = Int16(deprioritizedValue)
            }
        }
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
            return "Prioritized".localized
        case 1:
            return "Deprioritized".localized
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
