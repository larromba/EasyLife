//
//  ArchiveDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
import CoreData

class ArchiveDataSource {
    var dataManager: DataManager
    weak var delegate: TableDataSourceDelegate?
    
    fileprivate let donePredicate: NSPredicate
    fileprivate let epoch: Date
    fileprivate var allData: [Date : [TodoItem]]?
    var data: [Date : [TodoItem]]
    var numOfSections: Int {
        return data.keys.count
    }
    var totalItems: Int {
        return data.reduce(0, { $0 + $1.value.count })
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    
    init() {
        dataManager = DataManager.shared
        epoch = Date(timeIntervalSince1970: 0) // used to key nil dates
        donePredicate = NSPredicate(format: "%K = true", argumentArray: ["done"])
        data = [Date : [TodoItem]]()
    }
    
    // MARK: - public
    
    func undo(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        item.done = false
        item.date = nil
        item.repeatState = RepeatState.none
        dataManager.save(success: { [weak self] in
            guard let `self` = self, let key = self.key(at: indexPath.section) else {
                return
            }
            self.removeItem(item, fromSection: key)
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func startSearch() {
        allData = data
    }
    
    func search(_ text: String) {
        guard let allData = allData else {
            return
        }
        guard text.characters.count > 0 else {
            data = allData
            delegate?.dataSorceDidLoad(self)
            return
        }
        for key in allData.keys {
            if let result = allData[key]?.filter({ (item: TodoItem) -> Bool in
                return item.name?.lowercased().contains(text.lowercased()) ?? false
            }), result.count > 0 {
                data[key] = result
            } else {
                data.removeValue(forKey: key)
            }
        }
        delegate?.dataSorceDidLoad(self)
    }
    
    func endSearch() {
        if let allData = allData {
            data = allData
            delegate?.dataSorceDidLoad(self)
        }
        allData = nil
    }
    
    // MARK: - private
    
    fileprivate func key(at index: Int) -> Date? {
        let keys = Array(data.keys).sorted(by: { $0 > $1 })
        guard index >= keys.startIndex, index < keys.endIndex else {
            return nil
        }
        return keys[index]
    }
    
    fileprivate func addItem(_ item: TodoItem, toSection section: Date) {
        let section = section.earliest
        var items = data[section]
        if items == nil {
            items = [TodoItem]()
        }
        items!.append(item)
        data[section] = items
    }
    
    fileprivate func removeItem(_ item: TodoItem, fromSection section: Date) {
        let section = section.earliest
        guard var items = data[section], let index = items.index(of: item) else {
            return
        }
        _ = items.remove(at: index)
        guard items.count > 0 else { // remove section if empty
            data.removeValue(forKey: section)
            return
        }
        data[section] = items
    }
}

// MARK: - TableDataSource

extension ArchiveDataSource: TableDataSource {
    typealias Object = TodoItem
    
    func load() {
        dataManager.fetch(entityClass: TodoItem.self, predicate: donePredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            for item in items {
                if let date = item.date as Date? {
                    self.addItem(item, toSection: date)
                } else {
                    self.addItem(item, toSection: self.epoch)
                }
            }
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func title(for section: Int) -> String? {
        guard let date = key(at: section) else {
            return nil
        }
        guard date != epoch.earliest else {
            return "no date".localized
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE dd/MM/yyyy"
        dateFormatter.locale = NSLocale.current
        return dateFormatter.string(from: date)
    }
    
    func item(at indexPath: IndexPath) -> TodoItem? {
        guard let key = key(at: indexPath.section), let items = data[key],
            indexPath.row >= indexPath.startIndex, indexPath.row < items.endIndex else {
                return nil
        }
        return items[indexPath.row]
    }
    
    func section(at index: Int) -> [TodoItem]? {
        guard let key = key(at: index) else {
            return nil
        }
        return data[key]
    }
}
