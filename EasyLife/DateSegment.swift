//
//  DateSegment.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

enum DateSegment: Int {
    case none
    case today
    case tomorrow
    case fewDays
    case week
    case biweek
    case triweek
    case month
    case quarter
    case halfyear
    case year
    case MAX
    
    func stringValue() -> String? {
        switch self {
        case .today:
            return "today".localized
        case .tomorrow:
            return "tomorow".localized
        case .fewDays:
            return "a few days".localized
        case .week:
            return "next week".localized
        case .biweek:
            return "2 weeks".localized
        case .triweek:
            return "3 weeks".localized
        case .month:
            return "1 month".localized
        case .quarter:
            return "a few months".localized
        case .halfyear:
            return "half a year".localized
        case .year:
            return "next year".localized
        case .none, .MAX:
            return nil
        }
    }
    
    func increment(date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .fewDays:
            return calendar.date(byAdding: .day, value: 3, to: date)
        case .week:
            return calendar.date(byAdding: .weekOfMonth, value: 1, to: date)
        case .biweek:
            return calendar.date(byAdding: .weekOfMonth, value: 2, to: date)
        case .triweek:
            return calendar.date(byAdding: .weekOfMonth, value: 3, to: date)
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarter:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .halfyear:
            return calendar.date(byAdding: .month, value: 6, to: date)
        case .year:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .today:
            return date
        case .none, .MAX:
            return nil
        }
    }
}
