//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/22/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject {
    
    var annotation = MKPointAnnotation()
    
    convenience init(latitude:Double, longitude: Double, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        }else{
            fatalError("there was an error with the initalization")
        }
        
        self.annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    

}
