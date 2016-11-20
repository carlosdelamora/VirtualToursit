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

class MapViweController: UIViewController{
    
    let client = FlickFinderClient.sharedInstance()
    var editMode = false
    var annotations = [MKPointAnnotation]()
    
    
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
        
        //populate the map
        mapView.addAnnotations(annotations)
        viewToDeletePins.alpha = 0.5
        
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
            print("drop a pin in \(viewCoordinates) the map coordinates \(mapCoordinates)")
        }
        
    }
    
    
    
    
}

extension MapViweController: MKMapViewDelegate{
    
    //we use this delegate function to animate the pinViews drop and to paint them green
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil{ //if the pin is not present on the view it is nil?
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            //pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .green
            //pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }else{
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //we use this delegate function to respond to taps on the pins
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("edit mode is \(editMode)")
        if editMode{
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

           let method = client.flickURLFromParameters(methodParameters)
            client.flickGetMethod(method){jsonData, error in
                self.closureForGetMethod(jsonData, error as NSError?)
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

    func closureForGetMethod(_ jsonData:[String: AnyObject], _ error: NSError?){
        
        guard (error == nil) else{
            print("There was an error in closure ForGetMethod \(error)")
            return
        }
        
        let controller = storyboard?.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
        self.navigationController?.pushViewController(controller, animated: true)
        let backButton = UIBarButtonItem()
        backButton.title = "OK"
        backButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Helvetica", size: 20)!], for: UIControlState.normal)
        navigationItem.backBarButtonItem = backButton

        print("\(jsonData)")
    }
    
}


