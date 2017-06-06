//
//  TableDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 06/06/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

protocol TableDataSourceDelegate: class {
    func dataSorceDidLoad(_ dataSource: TableDataSource)
}

protocol TableDataSource {
    weak var delegate: TableDataSourceDelegate? { get set }
    
    func load()
    func title(for section: Int) -> String?
    func item(at indexPath: IndexPath) -> TodoItem?
    func section(at index: Int) -> [TodoItem]?
}
