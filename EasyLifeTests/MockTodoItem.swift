//
//  MockTodoItem.swift
//  EasyLife
//
//  Created by Lee Arromba on 19/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
@testable import EasyLife

class MockTodoItem: TodoItem {
    var _name: String?
    override var name: String? {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    var _notes: String?
    override var notes: String? {
        get {
            return _notes
        }
        set {
            _notes = newValue
        }
    }
    var _date: Date?
    override var date: Date? {
        get {
            return _date
        }
        set {
            _date = newValue
        }
    }
    var _repeats: Int16 = 0
    override var repeats: Int16 {
        get {
            return _repeats
        }
        set {
            _repeats = newValue
        }
    }
    var _done: Bool = false
    override var done: Bool {
        get {
            return _done
        }
        set {
            _done = newValue
        }
    }
    var _project: Project? = nil
    override var project: Project? {
        get {
            return _project
        }
        set {
            _project = newValue
        }
    }
}
