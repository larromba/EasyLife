//
//  TodoItem+CoreDataProperties.swift
//  EasyLife
//
//  Created by Lee Arromba on 13/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation
import CoreData


extension TodoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodoItem> {
        return NSFetchRequest<TodoItem>(entityName: "TodoItem");
    }

    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var date: NSDate?
    @NSManaged public var repeats: Int16
    @NSManaged public var done: Bool

}
