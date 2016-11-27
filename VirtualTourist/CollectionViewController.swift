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
    
    var activityIndicator: UIActivityIndicatorView!
    let client = FlickFinderClient.sharedInstance()
    var pin: Pin? //the pin should be no nil now, was set by the MapViewController
    var array = [Photo]()
    var context : NSManagedObjectContext? = nil
    var dataIsDownloading: Bool = true
    var firstDawnload: Bool = true
    var preliminaryPhotoArray = [Int]()
    var numberOfNewCollection: Int = 1
    
    @IBOutlet weak var newCollectionView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        
        //It does not look exactly as the demo app, I do not know how to make the border line to go even thiner. If I change the value below 0.25 the border disappears 
        self.newCollectionView.layer.borderWidth = 0.25
        
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
        
        
        //check if there is any pictures stored for this pin
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "photoToPin = %@", argumentArray: [pin!])
        fetchRequest.predicate = predicate
        
        do{
            if let results = try context?.fetch(fetchRequest) as? [Photo]{
                print("we have this number of photos \(results.count)")
                array = results
            }
        }catch{
            fatalError("can not get the photos form core data")
        }
        
        if (array.count) > 0{
            firstDawnload = false
            dataIsDownloading = false
            print("the array is \(array)")
            
        }else{
            print("we do not have results")
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
         print("the number of items in the array is \(array.count)")
        /*performUIUpdatesOnMain {
            self.collectionView?.reloadData()
        }*/
        

    }
    
    
    @IBAction func newCollectionButton(_ sender: Any) {
        
        //TODO set the code to get a new Collection.
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
            
            //we use preliminaryPhotoArray to know as soon as possible how many pictures are there and know how many cells with activity views to present.
             preliminaryPhotoArray = (1...photosDictionaryArray.count).map({$0})
             print("preliminary photo array \(preliminaryPhotoArray.count) while photoDictionary has \(photosDictionaryArray.count)")
            
             performUIUpdatesOnMain {
                self.collectionView?.reloadData()
             }
            
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
             dataIsDownloading = false
            
             performUIUpdatesOnMain {
                self.collectionView?.reloadData()
             }
            
            
            print(" the number of photos in the arrayOfPhotos is \(array.count)")
         
         }
     }
    
    
    
}


extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let a = firstDawnload ? preliminaryPhotoArray.count : array.count
        print("numbersOfItemsInSection got called, the array has \(preliminaryPhotoArray.count)")
        return min(27, a)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as!
        CollectionCell
        print("collectionView got called")
        if dataIsDownloading {
            print("data is downloading")
            addActyIndicator(cell.imageView)
        }else{
            print("we have pictures in the array")
            let photo = array[indexPath.row]
            let data = photo.imageData
            let image = UIImage(data: data as! Data)
            cell.imageView.image = image
            
            //we should only call this when is the first download, then dataIsDownloading changes form true to false when it stops downloading we had added the activity indicator and now can be removed. If is not the first download then dataIsDownloading is always false an thus addActivityIndicator never gets called and thus no need to removeActivityIndicator otherwise will crash.
            if firstDawnload{
                removeActivityIndicator()
            }
        }
        return cell
    }
    
    func addActyIndicator( _ cellView: UIImageView){
        activityIndicator = UIActivityIndicatorView( frame: cellView.bounds)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0.5, alpha: 0.25)
        activityIndicator.startAnimating()
        cellView.addSubview(activityIndicator)
    }
    
    func removeActivityIndicator(){
        activityIndicator.removeFromSuperview()
    }
    
}

