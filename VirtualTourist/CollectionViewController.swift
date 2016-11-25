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
    
    //var annotation: MKAnnotation?
    var pin: Pin?
    var array = [Photo]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        mapView.region.center = pin!.annotation.coordinate
        var nearSpan = MKCoordinateSpan()
        nearSpan.latitudeDelta = 1
        nearSpan.longitudeDelta = 1
        mapView.region.span = nearSpan
        mapView.addAnnotation(pin!.annotation)
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
         print("the nomber of items in the array is \(array.count)")
        self.collectionView?.reloadData()

    }
}
    

extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(27, array.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as!
        CollectionCell
        let photo = array[indexPath.row] 
        let data = photo.imageData
        let image = UIImage(data: data as! Data)
        cell.imageView.image = image
        return cell
    }
}

