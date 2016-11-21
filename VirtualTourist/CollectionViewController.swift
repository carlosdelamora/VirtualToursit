//
//  CollectionViewController.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/17/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

//import Foundation
import MapKit
import UIKit


class CollectionViewController: UIViewController{
    
    var annotation: MKAnnotation?
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        mapView.region.center = annotation!.coordinate
        var nearSpan = MKCoordinateSpan()
        nearSpan.latitudeDelta = 1
        nearSpan.longitudeDelta = 1
        mapView.region.span = nearSpan
        mapView.addAnnotation(annotation!)
    }

    
}
    

extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1//placeHolder
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        return cell
    }
}

