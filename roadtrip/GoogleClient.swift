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

class GoogleClient {
    
    let session = URLSession(configuration: .default)
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var googlePlacesKey: String?
    
    func getGooglePlacesData(forKeyword keyword: String, location: CLLocation, withinMeters radius: Int, using completionHandler: @escaping (GooglePlacesResponse) -> ())  {
        googlePlacesKey = appDelegate?.googlePlacesAPIKey
        let url = RoadtripAPI.googlePlacesDataURL(forKey: googlePlacesKey!, location: location, keyword: keyword,token: pagetoken)
        
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
    
}




