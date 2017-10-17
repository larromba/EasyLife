//
//  MockProject.swift
//  EasyLife
//
//  Created by Lee Arromba on 02/09/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
@testable import EasyLife

class MockProject: Project {
    var _name: String?
    override var name: String? {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var _priority: Int16 = -1
    override var priority: Int16 {
        get {
            return _priority
        }
        set {
            _priority = newValue
        }
    }
}
