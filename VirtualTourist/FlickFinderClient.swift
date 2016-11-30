//
//  FlickFinderClient.swift
//  VirtualTourist
//
//  Created by Carlos De la mora on 11/18/16.
//  Copyright © 2016 Carlos De la mora. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class FlickFinderClient:NSObject{
    
    //this function allows us to have a shared instance
   class func sharedInstance()-> FlickFinderClient {
        struct Singelton{
             static var sharedInstance = FlickFinderClient()
        }
        return Singelton.sharedInstance
    }
    

    //the function creates a URL with accpeted ASCII characters 
    func flickURLFromParameters(_ parameters: [String: String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    func flickGetMethod(_ methodURL: URL, _ completionHandeler: @escaping ([String: AnyObject], Error?)-> Void){
        print("flickerGetMethod was called")
        print("method \(methodURL)")
        let session = URLSession.shared
        let request = URLRequest(url: methodURL)
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                    //TODO: display errors
                }
            }
            
            if (error != nil){
            
                    //TODO: check for the error
                    completionHandeler([String: AnyObject](),error)
                
                
                displayError("\(error)")
                
            }
            
            guard let jsonData = self.closureForTask(data, response, error) else{
                displayError("there was an error")
                return
            }
            
            //if there is no error we use this completion handeler on GCD
            
                completionHandeler(jsonData, nil)
    
            
        }
        
        // start the task!
        task.resume()
    

    }
    
    //we use this closure for task to get a jsonData as a [String: AnyObject]?
    func closureForTask(_ data: Data?, _ response:URLResponse?, _ error:Error?)->[String: AnyObject]?{
        
        var jsonData: Any!
        guard (error == nil) else {
            print("There was an error with your request: \(error)")
            return nil
        }
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
            print("Your request returned a status code \((response as? HTTPURLResponse)?.statusCode)")
            //print("\(response as? HTTPURLResponse)?.statusCode)")
            return nil
        }
        /* GUARD: Was there any data returned? */
        guard let data = data else {
            print("No data was returned by the request!")
            return nil
        }
        /* subset response data! */
        do{jsonData = try JSONSerialization.jsonObject(with: data, options:.allowFragments)}catch{
            print("the json data could not be obtained")
        }
        
        //print("here is the jsonData closureForTask \(jsonData)")
        return jsonData as? [String:AnyObject]
    }

    
    
    
}
