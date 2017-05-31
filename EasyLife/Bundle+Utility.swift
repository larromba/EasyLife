//
//  Bundle+Utility.swift
//  EasyLife
//
//  Created by Lee Arromba on 31/05/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

extension Bundle {
    class func appVersion() -> String {
        return "v\(main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")"
    }
}
