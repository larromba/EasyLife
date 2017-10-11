//
//  TodoItem+Utility.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
import CoreData

extension TodoItem {
    var repeatState: RepeatState? {
        get {
            return RepeatState(rawValue: Int(repeats))
        }
        set {
            repeats = Int16(newValue?.rawValue ?? 0)
        }
    }
    
    func incrementDate() {
        guard let oldDate = date, let repeatState = repeatState else {
            return
        }
        date = repeatState.increment(date: oldDate as Date)
    }
}
