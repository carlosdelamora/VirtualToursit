//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/16/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViweController: UIViewController{
    
    let client = FlickFinderClient.sharedInstance()
    var editMode = false
    var annotations = [MKPointAnnotation]()
    var regionDictionary = [String: Double]()
    var context : NSManagedObjectContext? = nil
    var pins = [Pin]()
    
    @IBOutlet weak var mapView: MKMapView!
    
   
    @IBOutlet weak var viewToDeletePins: UIView!
    
    @IBOutlet weak var buttonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        //configurate the button item style
        buttonItem.title = "Edit"
        buttonItem.setTitleTextAttributes([NSFontAttributeName: UIFont(name:"Helvetica", size:20)!], for: UIControlState.normal)
        
        //set the recognizer to the view
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(dropAPin))
        longGesture.minimumPressDuration = CFTimeInterval(0.5)
        mapView.addGestureRecognizer(longGesture)
        
        
        viewToDeletePins.alpha = 0.5
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let stack = appDelegate.stack
        context = stack?.context
        
        }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //if the region has been set before we want persistance
        if let regionDictionary = UserDefaults.standard.value(forKey: "mapRegion") as? [String: Double]{
            
            mapView.region.center.latitude = regionDictionary["latitude"]!
            mapView.region.center.longitude = regionDictionary["longitude"]!
            var span = MKCoordinateSpan()
            span.latitudeDelta = regionDictionary["latitudeDelta"]!
            span.longitudeDelta = regionDictionary["longitudeDelta"]!
            mapView.region.span = span
            print("the view will appear the latutude delta is \(regionDictionary["latitudeDelta"]!)")
            print(mapView.region.span.latitudeDelta)
        }
        
        //populate the map
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do{
            if let results = try context?.fetch(fetchRequest) as? [Pin]{
                pins = results
            }
        }catch{
            fatalError("can not obtain the Pins")
        }
        
        annotations = pins.map({$0.annotation})
        print("we have this number of annotations \(annotations.count)")
        mapView.addAnnotation(annotations.first!)
        print("this is the first coordinate annotation \(pins.first!.annotation.coordinate)")
        mapView.addAnnotations(annotations)
        
    }

    
    @IBAction func editAction(_ sender: Any) {
        
        
        //we start to edit the pins
        if buttonItem.title == "Edit"{
            editMode = true
            UIView.animate(withDuration: 0.5){
                self.viewToDeletePins.center.y -= self.viewToDeletePins.frame.size.height
                self.mapView.frame.origin.y -= self.viewToDeletePins.frame.size.height
                self.viewToDeletePins.alpha = 1.0
            }
            buttonItem.title = "Done"
        }else{
            //we are done editing the pins
            editMode = false
            UIView.animate(withDuration: 0.5){
            self.viewToDeletePins.center.y += self.viewToDeletePins.frame.size.height
            self.mapView.frame.origin.y = 0
            self.viewToDeletePins.alpha = 0.5
            }
            buttonItem.title = "Edit"
        }
        
    }
    
    
    func dropAPin(){
        
        //get the gesture
        let longGesture = mapView.gestureRecognizers!.first
        
        
        //meake sure the gesture is at the begining of the state when it gets called to avoid calling more than once. 
        if longGesture?.state == UIGestureRecognizerState.began{
            // get the phone coordinates of the gesture
            let viewCoordinates = longGesture?.location(in: mapView)
            //translate the coordinates into map coordinates
            let mapCoordinates = mapView.convert(viewCoordinates!, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = mapCoordinates
            annotations.append(annotation)
            mapView.addAnnotation(annotation)
            print("pin droped in \(annotation.coordinate)")
            //create Pin to save it into core Data
            let pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context!)
            print("the new pin deropded has coordinates\(pin.annotation.coordinate)")
        }
        
    }
    
    
    
    
}

extension MapViweController: MKMapViewDelegate{
    
    //we use this delegate function to animate the pinViews drop and to paint them green
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil{
            //if the pin is not present on the mapView it is nil
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .green
        }else{
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func pinFromAnnotation(_ annotation: MKAnnotation)-> Pin?{
        
        //we get the current array of pins
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do{
            if let results = try context?.fetch(fetchRequest) as? [Pin]{
                pins = results
            }
        }catch{
            fatalError("can not obtain the Pins")
        }
        
        //we now check wich pins have the same annotation thant the one that was errased
        let pinSelected = pins.filter({ $0.annotation.coordinate.latitude ==
            annotation.coordinate.latitude && $0.annotation.coordinate.longitude == annotation.coordinate.longitude}).first
        
        return pinSelected
    }
    
    //we use this delegate function to respond to taps on the pins
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let pinSelected = pinFromAnnotation(view.annotation as! MKPointAnnotation)
        
        
        if editMode{
            
            if let pinToRemove = pinSelected {
                context?.delete(pinToRemove)
                print("the pin was removed")
            }
            
            //we want to delete the pin
            mapView.removeAnnotation(view.annotation!)
            
        }else{
           
            // we need the parameters to search near the annotation
           let methodParameters = [
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                Constants.FlickrParameterKeys.BoundingBox: bboxString(view.annotation?.coordinate.latitude, view.annotation?.coordinate.longitude),
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ] 
            
            print("flickerGetMethod should be called in the map view did select")
            let method = client.flickURLFromParameters(methodParameters)
            client.flickGetMethod(method,view){jsonData,view, error in
                self.closureForGetMethod(jsonData, view, error as NSError?)
            }
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

    func closureForGetMethod(_ jsonData:[String: AnyObject], _ view:MKAnnotationView, _ error: NSError?){
        
        guard (error == nil) else{
            print("There was an error in closure ForGetMethod \(error)")
            return
        }
        
        let thePin = self.pinFromAnnotation(view.annotation!)
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
        
        performUIUpdatesOnMain {
        
        self.navigationController?.pushViewController(controller, animated: true)
        //set the button with the right title and font
        let backButton = UIBarButtonItem()
        backButton.title = "OK"
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Helvetica", size: 20)!], for: UIControlState.normal)
        controller.navigationItem.backBarButtonItem = backButton
        
        //set the pin in the controller
        controller.pin = thePin
        
        }
        
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
            let arrayOfPhotos = noNullDataArray.map({Photo($0!, thePin!, context!)})
            
            controller.array = arrayOfPhotos
            print(" the number of photos in the arrayOfPhotos is \(arrayOfPhotos.count)")
        
        }
    }
    
    
    //get persistent data for the region
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        regionDictionary["latitude"] = mapView.region.center.latitude
        regionDictionary["longitude"] = mapView.region.center.longitude
        regionDictionary["latitudeDelta"] = mapView.region.span.latitudeDelta
        regionDictionary["longitudeDelta"] = mapView.region.span.longitudeDelta
        UserDefaults.standard.set(regionDictionary, forKey: "mapRegion")
    }
        
}


