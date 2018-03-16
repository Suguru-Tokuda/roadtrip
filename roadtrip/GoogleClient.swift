//
//  GoogleClient.swift
//  roadtrip
//
//  Created by sanket bhat on 3/11/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

var pagetoken = ""
//protocol GoogleClientRequest {
//    var googlePlacesKey : String { get set }
//    func getGooglePlacesData(forKeyword keyword: String, location: CLLocation,withinMeters radius: Int, using completionHandler: @escaping (GooglePlacesResponse) -> ())
//}

class GoogleClient {
    
    let session = URLSession(configuration: .default)
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var googlePlacesKey: String?
    
    func getGooglePlacesData(forKeyword keyword: String, location: CLLocation, withinMeters radius: Int, using completionHandler: @escaping (GooglePlacesResponse) -> ())  {
        googlePlacesKey = appDelegate?.googlePlacesAPIKey
        let url = googlePlacesDataURL(forKey: googlePlacesKey!, location: location, keyword: keyword,token: pagetoken)
        
        
        let task = self.session.dataTask(with: url) { (responseData, _, error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            
            guard let data = responseData else { return }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(GooglePlacesResponse.self, from: data)
                pagetoken = response.nextpagetoken ?? ""
                print("page token - \(pagetoken)")
                //                completionHandler(GooglePlacesResponse(results:[]))
                completionHandler(response)
            } catch let err {
                print("Err", err)
            }
        }
        task.resume()
        
    }
    
    func googlePlacesDataURL(forKey apiKey: String, location: CLLocation, keyword: String, token: String) -> URL {
        
        let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        let locationString = "location=" +     String(location.coordinate.latitude) + "," + String(location.coordinate.longitude)
        let rankby = "rankby=distance"
        let keywrd = "keyword=" + keyword
        let key = "key=" + apiKey
        let pagetoken = "pagetoken="+token
        
        return URL(string: baseURL + locationString + "&" + rankby + "&" + keywrd + "&" + key + "&" + pagetoken)!
    }
    
}




