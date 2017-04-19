//
//  Log.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

func log(_ item: Any) {
    #if DEBUG
        print(item)
    #endif
}
