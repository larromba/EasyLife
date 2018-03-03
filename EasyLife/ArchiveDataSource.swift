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

    fileprivate let unknownSection = Character("-")
    fileprivate let donePredicate: NSPredicate
    fileprivate var allData: [Character : [TodoItem]]?
    var data: [Character : [TodoItem]]
    var numOfSections: Int {
        return data.keys.count
    }
    var totalItems: Int {
        return data.reduce(0, { $0 + $1.value.count })
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    var isSearching: Bool {
        return allData != nil
    }
    
    init() {
        dataManager = DataManager.shared
        donePredicate = NSPredicate(format: "%K = true", argumentArray: ["done"])
        data = [Character : [TodoItem]]()
    }
    
    // MARK: - public
    
    func undo(at indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        item.done = false
        item.date = nil
        item.repeatState = RepeatState.none
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            guard let `self` = self, let key = self.key(at: indexPath.section) else {
                return
            }
            self.removeItem(item, fromSection: key)
            self.delegate?.dataSorceDidLoad(self)
        })
    }

    func clearAll() {
        let items = data.values.map { $0 }.flatMap { $0 }
        items.forEach { item in
            dataManager.delete(item, context: dataManager.mainContext)
        }
        data.removeAll()
        dataManager.save(context: dataManager.mainContext, success: { [weak self] in
            guard let `self` = self else {
                return
            }
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
        guard !text.isEmpty else {
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
    
    fileprivate func key(at index: Int) -> Character? {
        let keys = Array(data.keys).sorted(by: { $0 < $1 })
        guard index >= keys.startIndex, index < keys.endIndex else {
            return nil
        }
        return keys[index]
    }
    
    fileprivate func addItem(_ item: TodoItem, toSection section: Character) {
        var items = data[section] ?? [TodoItem]()
        items.append(item)
        data[section] = items.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
    }
    
    fileprivate func removeItem(_ item: TodoItem, fromSection section: Character) {
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
        dataManager.fetch(entityClass: TodoItem.self, context: dataManager.mainContext, predicate: donePredicate, success: { [weak self] (result: [Any]?) in
            guard let `self` = self, let items = result as? [TodoItem] else {
                return
            }
            for item in items {
                if let name = item.name, !name.isEmpty {
                    self.addItem(item, toSection: Character(String(name[name.startIndex]).uppercased()))
                } else {
                    self.addItem(item, toSection: self.unknownSection)
                }
            }
            self.delegate?.dataSorceDidLoad(self)
        })
    }
    
    func title(for section: Int) -> String? {
        guard let section = key(at: section) else {
            return nil
        }
        return String(section)
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
