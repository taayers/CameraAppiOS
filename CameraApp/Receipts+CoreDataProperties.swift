//
//  Receipts+CoreDataProperties.swift
//  CameraApp
//
//  Created by Todd on 12/12/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import Foundation
import CoreData


extension Receipts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Receipts> {
        return NSFetchRequest<Receipts>(entityName: "Receipts");
    }

    @NSManaged public var date: Date?
    @NSManaged public var imageLocation: String
    @NSManaged public var store: String?
    @NSManaged public var total: String?
    @NSManaged public var isPhotoReceipt: Bool

}
