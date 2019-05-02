//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/3/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation

extension Location
{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location>
    {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var category: String
    @NSManaged public var date: Date
    @NSManaged public var latitude: Double
    @NSManaged public var locationDescription: String
    @NSManaged public var longitude: Double
    @NSManaged public var photoID: NSNumber?
    @NSManaged public var placemark: CLPlacemark?
}
