//
//  EnumExtensions.swift
//  EasyLife
//
//  Created by Lee Arromba on 21/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

protocol EnumExtensions {
    static func count() -> Int
}

extension EnumExtensions where Self : RawRepresentable, Self.RawValue == Int {
    static func count() -> Int {
        var max: Int = 0
        while let _ = Self(rawValue: max) { max += 1 }
        return max
    }
}
