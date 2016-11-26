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
import CoreData

class CollectionViewController: UIViewController{
    
    
    let client = FlickFinderClient.sharedInstance()
    var pin: Pin?
    var array = [Photo]()
    var context : NSManagedObjectContext? = nil
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        
        // set the context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        
        //we use the pin infromation send to us by the mapViewController to set the region of the mapView
        mapView.region.center = pin!.annotation.coordinate
        var nearSpan = MKCoordinateSpan()
        nearSpan.latitudeDelta = 1
        nearSpan.longitudeDelta = 1
        mapView.region.span = nearSpan
        mapView.addAnnotation(pin!.annotation)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //we get the pictures form the internet
        // we need the parameters to search near the annotation
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(pin!.annotation.coordinate.latitude, pin!.annotation.coordinate.longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        print("flickerGetMethod should be called in the map view did select")
        let method = client.flickURLFromParameters(methodParameters)
        client.flickGetMethod(method){ jsonData, error in
            self.closureForGetMethod(jsonData, error as NSError?)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
         print("the nomber of items in the array is \(array.count)")
        self.collectionView?.reloadData()

    }
    
    private func bboxString(_ latitude: Double?, _ longitude: Double?) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = latitude, let longitude = longitude{
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    
    func closureForGetMethod(_ jsonData:[String: AnyObject], _ error: NSError?){
     
         guard (error == nil) else{
             print("There was an error in closure ForGetMethod \(error)")
             return
         }
     
         let controller = self.storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
     
         // get the photos and instanciate them
         /* GUARD: Is the "photos" key in our  jsonData */
         guard let photosDictionary = jsonData[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
             print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(jsonData)")
             return
         }
     
         /* GUARD: Is the "photo" key in photosDictionary? */
         guard let photosDictionaryArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
         print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(jsonData)")
         return
         }
     
         if photosDictionaryArray.count == 0 {
         print("No Photos Found. Search Again.")
         return
         }else {
         
         func getDataFromArray(_ photoDictionary: [String: AnyObject]) -> Data?{
         guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else{
         print("the imageURLstring was not cast as a string we return nil for the data")
         return nil
         }
         
         guard let url = URL(string: imageUrlString) else{
         print("the url was not cast as a string we return nil for the data")
         return nil
         }
         
         guard let imageData = try? Data(contentsOf: url)else{
         return nil
         }
         
         return imageData
         
         }
         
         let dataArray = photosDictionaryArray[0...27].map({ getDataFromArray($0)})
         let noNullDataArray = dataArray.filter({$0 != nil})
         array = noNullDataArray.map({Photo($0!, pin!, context!)})
            
          //Do we need to perform uptadets in main queue? it does not seem to block if is not there 
         performUIUpdatesOnMain {
            self.collectionView?.reloadData()
         }
        print(" the number of photos in the arrayOfPhotos is \(array.count)")
         
     }
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

