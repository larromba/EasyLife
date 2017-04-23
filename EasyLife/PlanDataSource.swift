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
    
    fileprivate var missedPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K < %@ AND %K = NULL", argumentArray: ["date", date.earliest, "done"])
    }
    fileprivate var todayPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "%K >= %@ AND %K <= %@ AND %K = NULL", argumentArray: ["date", date.earliest, "date", date.latest, "done"])
    }
    fileprivate var laterPredicate: NSPredicate {
        let date = today
        return NSPredicate(format: "(%K > %@ OR %K = NULL) AND %K = NULL", argumentArray: ["date", date.latest, "date", "done"])
    }
    var today: Date {
        return Date()
    }
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
    
    func itunesConnect() {
        let missed1 = dataManager.insert(entityClass: TodoItem.self)!
        missed1.date = Date().addingTimeInterval(-24*60*60) as NSDate?
        missed1.name = "send letter"
        
        let now1 = dataManager.insert(entityClass: TodoItem.self)!
        now1.date = Date() as NSDate?
        now1.name = "fix bike"
        
        let now2 = dataManager.insert(entityClass: TodoItem.self)!
        now2.date = Date() as NSDate?
        now2.name = "get party food!"
        
        let later1 = dataManager.insert(entityClass: TodoItem.self)!
        later1.date = Date().addingTimeInterval(24*60*60) as NSDate?
        later1.name = "phone mum"
        
        let later2 = dataManager.insert(entityClass: TodoItem.self)!
        later2.date = Date().addingTimeInterval(24*60*60) as NSDate?
        later2.name = "clean flat"
        
        let later3 = dataManager.insert(entityClass: TodoItem.self)!
        later3.date = Date().addingTimeInterval(24*60*60) as NSDate?
        later3.name = "call landlord"
        
        dataManager.save()
    }

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
        switch item.repeatState! {
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
        switch item.repeatState! {
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
        guard section >= 0 && section < sections.count && sections[section].count > 0 else {
            return nil
        }
        switch section {
        case 0:
            return "Missed...".localized
        case 1:
            return "Today".localized
        case 2:
            return "Later...".localized
        default:
            return nil
        }
    }
    
    // MARK: - private
    
    fileprivate func data(at indexPath: IndexPath) -> TodoItem? {
        guard indexPath.section >= sections.startIndex && indexPath.section < sections.endIndex else {
            return nil
        }
        let section = sections[indexPath.section]
        guard indexPath.row >= section.startIndex && indexPath.row < section.endIndex else {
            return nil
        }
        let row = section[indexPath.row]
        return row
    }
}
