//
//  RepeatStateTests.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import XCTest
import CoreData
@testable import EasyLife

class RepeatStateTests: XCTestCase {
    // test display
    func test1() {
        XCTAssertEqual(RepeatState.display.count, 9)
    }
    
    // test increment
    func test2() {
        // mocks
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = dateFormatter.date(from: "21/04/2017")!
        
        // test
        for i in 1..<RepeatState.display.count {
            let a = RepeatState.display[i]
            let date2 = a.increment(date: date)
            switch a {
            case .daily:
                XCTAssertEqual(dateFormatter.date(from: "22/04/2017")!, date2)
            case .weekly:
                XCTAssertEqual(dateFormatter.date(from: "28/04/2017")!, date2)
            case .biweekly:
                XCTAssertEqual(dateFormatter.date(from: "05/05/2017")!, date2)
            case .triweekly:
                XCTAssertEqual(dateFormatter.date(from: "12/05/2017")!, date2)
            case .monthly:
                XCTAssertEqual(dateFormatter.date(from: "21/05/2017")!, date2)
            case .quarterly:
                XCTAssertEqual(dateFormatter.date(from: "21/07/2017")!, date2)
            case .halfyear:
                XCTAssertEqual(dateFormatter.date(from: "21/10/2017")!, date2)
            case .yearly:
                XCTAssertEqual(dateFormatter.date(from: "21/04/2018")!, date2)
            case .none:
                break
            }
        }
    }
}
