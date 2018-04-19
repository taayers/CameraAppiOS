//
//  EmailAddresses+CoreDataProperties.swift
//  CameraApp
//
//  Created by Todd on 11/11/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import Foundation
import CoreData


extension EmailAddresses {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailAddresses> {
        return NSFetchRequest<EmailAddresses>(entityName: "EmailAddresses");
    }

    @NSManaged public var emailAddress: String?

}
