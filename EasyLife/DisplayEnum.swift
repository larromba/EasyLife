//
//  DisplayEnum.swift
//  EasyLife
//
//  Created by Lee Arromba on 21/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

protocol DisplayEnum: EnumExtensions {
    static var display: [Self] { get }
}
