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
    var repeatsState: Repeat? {
        get {
            return Repeat(rawValue: Int(repeats))
        }
        set {
            let value = newValue?.rawValue ?? 0
            repeats = Int16(value)
        }
    }
}
