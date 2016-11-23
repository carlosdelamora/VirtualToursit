//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/23/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import CoreData



public class Photo: NSManagedObject {
    convenience init(data: Data, context:NSManagedObjectContext){
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
        }else{
            fatalError("there was an error with initalization")
        }
    }
}
