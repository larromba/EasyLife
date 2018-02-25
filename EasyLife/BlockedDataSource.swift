//
//  BlockedDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 24/02/2018.
//  Copyright © 2018 Pink Chicken Ltd. All rights reserved.
//

import Foundation

class BlockedDataSource {
    var dataManager: DataManager
    weak var delegate: TableDataSourceDelegate?
    var data: [BlockedItem]!
    var item: TodoItem?
    let sectionCount = 1
    var rowCount: Int {
        return data.count
    }

    init() {
        dataManager = DataManager.shared
        data = [BlockedItem]()
    }

    func load() {
        delegate?.dataSorceDidLoad(self)
    }

    func toggle(_ indexPath: IndexPath) {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else {
            return
        }
        data[indexPath.row].isBlocked = !data[indexPath.row].isBlocked
        delegate?.dataSorceDidLoad(self)
    }

    func isBlocked(_ a: TodoItem) -> Bool {
        return data.filter({ $0.item === a }).first?.isBlocked ?? false
    }
}

// MARK: - TableDataSource

extension BlockedDataSource: TableDataSource {
    typealias Object = TodoItem

    func item(at indexPath: IndexPath) -> Object? {
        guard indexPath.row >= data.startIndex && indexPath.row < data.endIndex else {
            return nil
        }
        return self.data[indexPath.row].item
    }
}
