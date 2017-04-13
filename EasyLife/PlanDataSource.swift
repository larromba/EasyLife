//
//  PlanDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
import CoreData

protocol PlanDataSourceDelegate: class {
    func dataSorceDidLoad(_ dataSource: PlanDataSource)
}

class PlanDataSource {
    var dataManager: DataManager
    var sections: [[TodoItem]]
    weak var delegate: PlanDataSourceDelegate?
    
    fileprivate lazy var missedPredicate: NSPredicate = {
        return NSPredicate(format: "%K < %@ AND %K = NULL", argumentArray: ["date", Date().earliest(), "done"])
    }()
    
    fileprivate lazy var todayPredicate: NSPredicate = {
        let date = Date()
        return NSPredicate(format: "%K >= %@ AND %K <= %@ AND %K = NULL", argumentArray: ["date", date.earliest(), "date", date.latest(), "done"])
    }()
    
    fileprivate lazy var laterPredicate: NSPredicate = {
        return NSPredicate(format: "%K > %@ OR %K = NULL AND %K = NULL", argumentArray: ["date", Date().latest(), "date", "done"])
    }()
    
    var total: Int {
        return sections.reduce(0) { (result: Int, item: [TodoItem]) -> Int in
            return result + item.count
        }
    }
    
    init() {
        dataManager = DataManager.shared
        sections = [[TodoItem]](repeating: [TodoItem](), count: 3)
    }
    
    // MARK: - public

    func delete(at indexPath: IndexPath) {
        guard let item = data(at: indexPath) else {
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
    
    func later(at indexPath: IndexPath) {
        guard let item = data(at: indexPath) else {
            return
        }
        switch item.repeatsState! {
        case .none:
            item.date = nil
        default:
            item.incrementDate()
        }
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func done(at indexPath: IndexPath) {
        guard let item = data(at: indexPath) else {
            return
        }
        switch item.repeatsState! {
        case .none:
            item.done = true
        default:
            item.incrementDate()
        }
        dataManager.save(success: { [weak self] in
            self?.load()
        })
    }
    
    func load() {
        dataManager.fetch(entityClass: TodoItem.self, predicate: missedPredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items, at: 0)
            self.delegate?.dataSorceDidLoad(self)
        })
        dataManager.fetch(entityClass: TodoItem.self, predicate: todayPredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items, at: 1)
            self.delegate?.dataSorceDidLoad(self)
        })
        dataManager.fetch(entityClass: TodoItem.self, predicate: laterPredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            self.sections.replace(items, at: 2)
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func title(forSection section: Int) -> String? {
        guard sections[section].count > 0 else {
            return nil
        }
        switch section {
        case 0:
            return "Missed..." //TODO:localise
        case 1:
            return "Today"
        case 2:
            return "Later..."
        default:
            return nil
        }
    }
    
    // MARK: - private
    
    fileprivate func data(at indexPath: IndexPath) -> TodoItem? {
        guard indexPath.section < sections.endIndex && indexPath.row < sections[indexPath.section].endIndex else {
            return nil
        }
        return sections[indexPath.section][indexPath.row]
    }
}
