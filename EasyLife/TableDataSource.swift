//
//  TableDataSource.swift
//  EasyLife
//
//  Created by Lee Arromba on 06/06/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

protocol TableDataSourceDelegate: class {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T)
}

protocol TableDataSource {
    associatedtype Object
    
    weak var delegate: TableDataSourceDelegate? { get set }
    
    func load()
    func title(for section: Int) -> String?
    func item(at indexPath: IndexPath) -> Object?
    func section(at index: Int) -> [Object]?
}
