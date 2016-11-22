//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/22/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var photoToPin: Pin?

}
