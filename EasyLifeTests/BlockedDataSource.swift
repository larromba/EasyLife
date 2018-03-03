//
//  BlockedDataSource.swift
//  EasyLifeTests
//
//  Created by Lee Arromba on 25/02/2018.
//  Copyright © 2018 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class BlockedDataSourceTests: XCTestCase {
    func testToggle() {
        // mocks
        let dataSource = BlockedDataSource()

        // prepare
        dataSource.data = [BlockedItem(item: MockTodoItem(), isBlocked: false)]

        // test
        dataSource.toggle(IndexPath(row: 0, section: 0))
        XCTAssertTrue(dataSource.data![0].isBlocked)

        dataSource.toggle(IndexPath(row: 0, section: 0))
        XCTAssertFalse(dataSource.data![0].isBlocked)
    }
}
