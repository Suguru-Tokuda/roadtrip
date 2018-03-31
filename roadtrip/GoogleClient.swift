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

enum DirectionsResult {
    case success(Direction)
    case failure(Error)
}

class GoogleClient {
    
    let session = URLSession(configuration: .default)
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var googlePlacesKey: String?
    
    func getGooglePlacesData(forKeyword keyword: String, location: CLLocation, withinMeters radius: Int, using completionHandler: @escaping (GooglePlacesResponse) -> ())  {
        let url = RoadtripAPI.googlePlacesDataURL(location: location, keyword: keyword,token: pagetoken)
        
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
    
    func getDestinationPathByCoordinates(origin: CLLocation, destination: CLLocation, completion: @escaping (DirectionsResult) -> Void) {
        let originLat = origin.coordinate.latitude
        let originLong = origin.coordinate.longitude
        let destLat = destination.coordinate.latitude
        let destLong = destination.coordinate.longitude
        URLSession.shared.dataTask(with: RoadtripAPI.googleDirectionURLWithCoordinates(originLat: originLat, originLong: originLong, destLat: destLat, destLong: destLong)) {
            (data, response, error) -> Void in
            let result = self.processDirectionsRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }.resume()
    }
    
    private func processDirectionsRequest(data: Data?, error: Error?) -> DirectionsResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getDirectionsResult(fromJSON: jsonData)
    }
    
}




