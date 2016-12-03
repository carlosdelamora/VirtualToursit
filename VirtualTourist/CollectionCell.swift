//
//  CollectionCell.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/17/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import UIKit

class CollectionCell: UICollectionViewCell{
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    var editing: Bool = false {
        didSet{
            imageView.alpha = editing ? 0.2 : 1
        }
    }
}
