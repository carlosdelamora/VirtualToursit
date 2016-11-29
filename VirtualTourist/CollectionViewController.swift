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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var activityIndicator: UIActivityIndicatorView!
    let client = FlickFinderClient.sharedInstance()
    var pin: Pin? //the pin should be no nil now, was set by the MapViewController
    var arrayOfPhotos = [Photo]()
    var context : NSManagedObjectContext? = nil
    var dataIsDownloading: Bool = true
    var firstDawnload: Bool = true
    var placeHolderNumber: Int = 0
    var numberOfNewCollection: Int = 1
    var myDataArray = [Data?]()
    var preDataArray = [[String: AnyObject]]()
    
    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var newCollectionView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        print("view Did load got called")
        newCollectionButton.isEnabled = false
        newCollectionView.alpha = 0.25
        //It does not look exactly as the demo app, I do not know how to make the border line to go even thiner. If I change the value below 0.25 the border disappears 
        self.newCollectionView.layer.borderWidth = 0.3
        
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
                print("we have this number of photos in core data \(results.count)")
                arrayOfPhotos = results
            }
        }catch{
            fatalError("can not get the photos form core data")
        }
        
        if (arrayOfPhotos.count) > 0{
            firstDawnload = false
            dataIsDownloading = false
            self.newCollectionButton.isEnabled = true
            self.newCollectionView.alpha = 1
            
        }else{
            print("since we do not have photos form core data we get photos online")
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
            
            let method = client.flickURLFromParameters(methodParameters)
            client.flickGetMethod(method){ jsonData, error in
                self.closureForGetMethod(jsonData, error as NSError?)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("view Will appear got called may be realod data is called first here")
    }
    
    
    @IBAction func newCollectionButton(_ sender: Any) {
        
        //TODO set the code to get a new Collection.
        print("the button is enabled")
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
        
        // get the photos and instanciate them
        /* GUARD: Is the "photos" key in our  jsonData */
        guard let photosDictionary = jsonData[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
             print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(jsonData)")
             return
        }
        
        
        guard let total = Int((photosDictionary[Constants.FlickrResponseKeys.Total] as? String)!) else{
        print("there is not total in jsonData")
        return
        }
        
        // we use this number to populate the table with activity inidcators
        placeHolderNumber = min(total,21)
        performUIUpdatesOnMain {
            print("perform updates in main first ")
            self.collectionView?.reloadData()
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
            
            //we create myData array with max of 21 pictures
            myDataArray = photosDictionaryArray[0...placeHolderNumber-1].map({ getDataFromArray($0)})
            dataIsDownloading = false
            performUIUpdatesOnMain {
                print("perform updates in main first ")
                self.collectionView?.reloadData()
                self.newCollectionButton.isEnabled = true
                self.newCollectionView.alpha = 1
            }
            //Instantiate the photos in myDataArray and save them to core Data
            let _ = myDataArray.map({Photo($0!, pin!, context!)})

            
            //If we have more than 27 pictures downloaded we instantiate more photos to be saved in the core Data
            if total > 21{
                let extra = min(70,total)
                let dataArray = photosDictionaryArray[placeHolderNumber...extra].map({ getDataFromArray($0)})
                let noNullDataArray = dataArray.filter({$0 != nil}) as! [Data]
                arrayOfPhotos = noNullDataArray.map({Photo($0, pin!, context!)})
            }
        }
    }
}


extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let a = firstDawnload ? placeHolderNumber : arrayOfPhotos.count
        
        print("numbersOfItemsInSection got called, the placeHolderNumber array has \(placeHolderNumber)")
        print("a=\(a) is it first download \(firstDawnload)")
        return min(21, a)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as!
        CollectionCell
        print("collectionView got called")
        
        //if is the first download we use myDataArray which is an array that was recently downloaded
        if firstDawnload{
            //If data is downloading we place an acitvity indicator in the cell
            if dataIsDownloading {
                print("data is downloading")
                addActyIndicator(cell.imageView)
            }else{
                //if the data is no longer donwloading we place an image cell in the array
                print("we have pictures in the array")
                
                let data = myDataArray[indexPath.row]
                guard let image = UIImage(data: data!) else{
                    return cell
                }
                cell.imageView.image = image
            }
        }else{
            //If this is not the first download then then we get and arrayOfPhotos from Core Data
            let data = arrayOfPhotos[indexPath.row].imageData as! Data
            let image = UIImage(data: data)
            cell.imageView.image = image

        }
        return cell
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
        
        guard let imageData = try? Data(contentsOf: url) else{
            return nil
        }
        
        return imageData
        
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

