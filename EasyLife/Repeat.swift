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
    case biweekly
    case triweekly
    case monthly
    case quarterly
    case halfyear
    case yearly
    case MAX
    
    init?(rawString: String) {
        switch rawString {
        case "daily":
            self.init(rawValue: Repeat.daily.rawValue)
        case "weekly":
            self.init(rawValue: Repeat.weekly.rawValue)
        case "bi-weekly":
            self.init(rawValue: Repeat.biweekly.rawValue)
        case "tri-weekly":
            self.init(rawValue: Repeat.triweekly.rawValue)
        case "monthly":
            self.init(rawValue: Repeat.monthly.rawValue)
        case "quarterly":
            self.init(rawValue: Repeat.quarterly.rawValue)
        case "every 6 months":
            self.init(rawValue: Repeat.halfyear.rawValue)
        case "yearly":
            self.init(rawValue: Repeat.yearly.rawValue)
        default:
            log("unknown rawString: \(rawString)")
            return nil
        }
    }
    
    func stringValue() -> String? {
        switch self {
        case .daily:
            return "daily"
        case .weekly:
            return "weekly"
        case .biweekly:
            return "bi-weekly"
        case .triweekly:
            return "tri-weekly"
        case .monthly:
            return "monthly"
        case .quarterly:
            return "quarterly"
        case .halfyear:
            return "every 6 months"
        case .yearly:
            return "yearly"
        case .none, .MAX:
            return nil
        }
    }
    
    func increment(date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfMonth, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfMonth, value: 2, to: date)
        case .triweekly:
            return calendar.date(byAdding: .weekOfMonth, value: 3, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .halfyear:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .none, .MAX:
            return date
        }
    }
}
