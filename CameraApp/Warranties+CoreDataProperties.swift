//
//  Warranties+CoreDataProperties.swift
//  CameraApp
//
//  Created by Todd on 11/15/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import Foundation
import CoreData


extension Warranties {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Warranties> {
        return NSFetchRequest<Warranties>(entityName: "Warranties");
    }

    @NSManaged public var daysLeft: String?
    @NSManaged public var itemName: String?
    @NSManaged public var createdDate: Date?

}
