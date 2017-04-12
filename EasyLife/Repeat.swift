//
//  Repeat.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

enum Repeat: Int {
    case none
    case daily
    case weekly
    case monthly
    case yearly
    
    init?(rawString: String) {
        switch rawString {
        case "Daily":
            self.init(rawValue: Repeat.daily.rawValue)
        case "Weekly":
            self.init(rawValue: Repeat.weekly.rawValue)
        case "Monthly":
            self.init(rawValue: Repeat.monthly.rawValue)
        case "Yearly":
            self.init(rawValue: Repeat.yearly.rawValue)
        default:
            return nil
        }
    }
    
    func stringValue() -> String? {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        default:
            return nil
        }
    }
}
