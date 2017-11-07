//
//  TodoItemTests.swift
//  EasyLifeTests
//
//  Created by Lee Arromba on 07/11/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class TodoItemTests: XCTestCase {
    // date increments past today when far in the past
    func test1() {
        // mocks
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "07/01/2016")!.earliest
        let todoItem = MockTodoItem()
        
        // prepare
        todoItem._date = date
        todoItem._repeats = Int16(RepeatState.monthly.rawValue)
        
        // test
        todoItem.incrementDate()
        guard let incrementedDate = todoItem.date else {
            XCTFail()
            return
        }
        XCTAssertGreaterThan(incrementedDate, Date())
    }
}
