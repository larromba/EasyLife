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
        case "daily".localized:
            self.init(rawValue: Repeat.daily.rawValue)
        case "weekly".localized:
            self.init(rawValue: Repeat.weekly.rawValue)
        case "bi-weekly".localized:
            self.init(rawValue: Repeat.biweekly.rawValue)
        case "tri-weekly".localized:
            self.init(rawValue: Repeat.triweekly.rawValue)
        case "monthly".localized:
            self.init(rawValue: Repeat.monthly.rawValue)
        case "quarterly".localized:
            self.init(rawValue: Repeat.quarterly.rawValue)
        case "every 6 months".localized:
            self.init(rawValue: Repeat.halfyear.rawValue)
        case "yearly".localized:
            self.init(rawValue: Repeat.yearly.rawValue)
        default:
            log("unknown rawString: \(rawString)")
            return nil
        }
    }
    
    func stringValue() -> String? {
        switch self {
        case .daily:
            return "daily".localized
        case .weekly:
            return "weekly".localized
        case .biweekly:
            return "bi-weekly".localized
        case .triweekly:
            return "tri-weekly".localized
        case .monthly:
            return "monthly".localized
        case .quarterly:
            return "quarterly".localized
        case .halfyear:
            return "every 6 months".localized
        case .yearly:
            return "yearly".localized
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
