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
    var placeHolderNumber: Int = 0
    var preDataArray = [[String: AnyObject]]()
    var viewWillDisapear: Bool = false
    var attributes: NSAttributedString?
    let smallAlpha = CGFloat(0.25)
    
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var NoPhotosView: UIView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var newCollectionView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        
        newCollectionButton.setTitle("New Collection", for: .normal)
        print("view did load")
        print("we have the attributes \(newCollectionButton.currentAttributedTitle)")
        attributes = newCollectionButton.currentAttributedTitle
        collectionView!.allowsMultipleSelection = true
        collectionView.isHidden = false
        NoPhotosView.isHidden = true
        newCollectionButton.isEnabled = false
   
        newCollectionView.alpha = smallAlpha
        //It does not look exactly as the demo app, I do not know how to make the border line to go even thiner. If I change the value below 0.25 the border disappears 
        self.newCollectionView.layer.borderWidth = 0.3
        
        // set the context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        let persistentContext = stack?.persistingContext
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
        context?.performAndWait {
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [Photo]{
                    self.arrayOfPhotos = results
                }
            }catch{
                fatalError("can not get the photos form core data")
            }

        }
        
        if (arrayOfPhotos.count) > 0{
            dataIsDownloading = false
            newCollectionButton.isEnabled = true
            newCollectionView.alpha = 1
            
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
        super.viewWillAppear(animated)
        print("view Will appear got called may be realod data is called first here")
        //set the layout
        let width = view.frame.width/3
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
        print(layout.itemSize)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisapear = true 
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        //set the layout
        let width = size.width/3
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width)
    }
    
    @IBAction func newCollectionButtonTapped(_ sender: Any) {
        
        newCollectionButton.isEnabled = false
        if newCollectionButton.titleLabel!.text! == "New Collection"{
            let numberOfPhotos = preDataArray.count
            if 21 < numberOfPhotos{
                placeHolderNumber = min(numberOfPhotos,42)
                dataIsDownloading = true
                print("data is danwlading \(self.dataIsDownloading)")
                performUIUpdatesOnMainWithDelay {
                    self.collectionView!.reloadData()
                }
                preDataArray = Array(preDataArray[21...numberOfPhotos-1])
                //we need a delay so that reloadData has time to display the activity indicators
                DispatchQueue.global().async {
                    self.arrayOfPhotos = self.constructArrayOfPhotos(Array(self.preDataArray[21...self.placeHolderNumber-1]), self.pin!)
                    self.dataIsDownloading = false
                    self.collectionView?.reloadData()
                    self.newCollectionButton.isEnabled = true
                    self.newCollectionView.alpha = 1
                }
            }else{
                arrayOfPhotos = [Photo]()
                collectionView!.reloadData()
            }
            
        }else{
            print("we are in this part of the code")
            guard let indexPaths = collectionView!.indexPathsForSelectedItems else{
                return
            }
            var indexesToRemove = Set<Int>()
            for indexPath in indexPaths{
                var photos = [Photo]()
                let aPhoto = arrayOfPhotos[indexPath.item]
                let url_m = aPhoto.url_m!
                print("the url_m is \(url_m)")
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
                let predicate = NSPredicate(format: "url_m = %@", url_m)
                //let predicate = NSPredicate(format: "photoToPin = %@", argumentArray: [pin!])
                fetchRequest.predicate = predicate
                do{
                    photos = try context?.fetch(fetchRequest) as! [Photo]
                }catch{
                    print("we could not get the photo from the fetch")
                }
                
                if let photo = photos.first{
                    context?.delete(photo)
                }
                indexesToRemove.insert(indexPath.item)
            }
            arrayOfPhotos = arrayOfPhotos.enumerated().filter({!indexesToRemove.contains($0.offset)}).map({$0.element})
            collectionView.deleteItems(at: indexPaths)
            newCollectionButton.isEnabled = true
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
        
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
    
    func saves(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        stack?.saves()
    }

    
    func closureForGetMethod(_ jsonData:[String: AnyObject], _ error: NSError?){
     
        guard (error == nil) else{
             print("There was an error in closure ForGetMethod \(error)")
             return
        }
        
        // get the photos and instanciate them
        /* GUARD: Is the "photos" key in our  jsonData */
        guard let photosDictionary = jsonData[Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
             print("Cannot find key '\(Constants.FlickrResponseKeys.Photos)' in \(jsonData)")
             return
        }

        guard let total = Int((photosDictionary[Constants.FlickrResponseKeys.Total] as? String)!) else{
            print("there is not total in jsonData")
        return
        }
        
        // we use this number to populate the table with activity inidcators
        placeHolderNumber = min(total,21)
        performUIUpdatesOnMainWithDelay {
            self.collectionView?.reloadData()
        }
        
        /* GUARD: Is the "photo" key in photosDictionary? */
        guard let photosDictionaryArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
            print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(jsonData)")
            return
        }
        
        if photosDictionaryArray.count == 0 {
            print("this pin has no images should appear")
            performUIUpdatesOnMainWithDelay {
                self.collectionView.isHidden = true
                self.NoPhotosView.isHidden = false
                self.noImagesLabel.text = "This pin has no images"
            }
        }else {
            func getUrlString(_ photosDictionary:[String: AnyObject])->String?{
                guard let urlString = photosDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else{
                    return nil
                }
                return urlString
            }
            //we set the arrayOfPhotos
            arrayOfPhotos = constructArrayOfPhotos(Array(photosDictionaryArray[0...placeHolderNumber-1]),pin!)
            //now that we have the arrayOfPhotos we reload the collectionView
            dataIsDownloading = false
            print("we reload data")
            performUIUpdatesOnMainWithDelay {
                self.collectionView?.reloadData()
                self.newCollectionButton.isEnabled = true
                self.newCollectionView.alpha = 1
            }

            //we save the downoalded array
            preDataArray = photosDictionaryArray
        }
    }
    
    
       //we use this function to erase every photo in the pin, then create new arry of photos in core data fetch the results and display them in the collection view
    func constructArrayOfPhotos(_ preDataArray: [[String: AnyObject]], _ pin: Pin)-> [Photo]{
        
        var photosArray = [Photo]()
        for photo in arrayOfPhotos{
            context?.perform {
                self.context?.delete(photo)
            }
        }
        saves()
        //we get out of a photoDictionary to return the urlString
        func getUrlString(_ photosDictionary:[String: AnyObject])->String?{
            guard let urlString = photosDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else{
                return nil
            }
            return urlString
        }
        // We use this function to create Photos in core Data out of an array of urlStrings
        func createPhoto(_ urlStringArray: [String?], _ aPin: Pin? ){
            
            for imageUrlString in urlStringArray {
                
                if let imageUrlString = imageUrlString, let url = URL(string: imageUrlString), let imageData = try? Data(contentsOf: url), let aPin = aPin{
                    //if view is about to disapear we do not want to create more photos because we may erase a pin we are trying to attach a photo and that will crash the application. This may happen even after unwraping the aPin because by the time we save to the context the pin may not exist
                    if viewWillDisapear{
                        return
                    }
                    context?.perform{
                    let _ = Photo( imageUrlString, imageData, aPin, self.context!)
                    }
                }
            }
        }

        let myUrlArray = preDataArray.map({getUrlString($0)})
        let _ = createPhoto(myUrlArray, pin)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "photoToPin = %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        print("we fetch the request")
        context?.performAndWait {
            
            do{
                if let results = try self.context?.fetch(fetchRequest) as? [Photo]{
                    photosArray = results
                }
            }catch{
                fatalError("can not get the photos form core data")
            }
        }
        print("consturct array of photos is about to end")
        return photosArray
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
}


extension CollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let a = dataIsDownloading ? placeHolderNumber : arrayOfPhotos.count
        print("a=\(a)")
        return min(21, a)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as!
        CollectionCell
        
        print("collection View got called data is downloading \(dataIsDownloading)")
        //If is the first download we use myDataArray which is an array that was recently downloaded
        //If data is downloading we place an acitvity indicator in the cell
        if dataIsDownloading {
            performUIUpdatesOnMainWithDelay {
                cell.imageView.image = nil
                self.addActyIndicator(cell.imageView)
            }
        }else{
           //if the data is no longer donwloading we place an image cell in the array
            performUIUpdatesOnMainWithDelay {
                let photo = self.arrayOfPhotos[indexPath.row]
                guard let image = UIImage(data: photo.imageData as! Data) else{
                    return
                }
                cell.imageView.image = image
                if (collectionView.indexPathsForSelectedItems?.contains(indexPath))!{
                    cell.editing = true
                }else{
                    cell.editing = false
                }
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionCell
        cell.editing = true
        newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionCell
        cell.editing = false
        if collectionView.indexPathsForSelectedItems?.count == 0{
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
}

