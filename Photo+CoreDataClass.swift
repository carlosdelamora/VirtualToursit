//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 12/3/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    convenience init(_ url_m: String , _ data: Data, _ pin: Pin , _ context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.imageData = data as NSData
            self.photoToPin = pin
            self.url_m = url_m
        }else{
            fatalError("there was an error with initalization")
        }
    }
}
