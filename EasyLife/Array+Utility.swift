//
//  Array+Utility.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

extension Array {
    mutating func replace(_ newElement: Element, at i: Int) {
        remove(at: i)
        insert(newElement, at: i)
    }
}
