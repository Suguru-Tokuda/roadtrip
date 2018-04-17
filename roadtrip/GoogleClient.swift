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

enum DistanceResult {
    case success(Distance)
    case failure(Error)
}

enum PlaceDetailResult {
    case success(PlaceDetail)
    case failure(Error)
}

enum PhotosResult {
    case success([UIImage])
    case failure(Error)
}

class GoogleClient {
    
    let session = URLSession(configuration: .default)
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var googlePlacesKey: String?
    func getGooglePlacesData(forKeyword keyword: String, location: CLLocation, withinMeters radius: Int, using completionHandler: @escaping (GooglePlacesResponse) -> ())  {
        let url = RoadtripAPI.googlePlacesDataURL(location: location, keyword: keyword, radius: radius ,token: pagetoken)
        
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
    
    func getDirection(origin: CLLocation, destination: CLLocation, completion: @escaping (DirectionsResult) -> Void) {
        let originLat = origin.coordinate.latitude
        let originLong = origin.coordinate.longitude
        let destLat = destination.coordinate.latitude
        let destLong = destination.coordinate.longitude
        URLSession.shared.dataTask(with: RoadtripAPI.googleDirectionURL(originLat: originLat, originLong: originLong, destLat: destLat, destLong: destLong)) {
            (data, response, error) -> Void in
            let result = self.processDirectionsRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
            }.resume()
    }
    
    func getDirection(origin: CLLocation, destination: CLLocation, waypoint: CLLocation, completion: @escaping (DirectionsResult) -> Void) {
        let originLat = origin.coordinate.latitude
        let originLong = origin.coordinate.longitude
        let destLat = destination.coordinate.latitude
        let destLong = destination.coordinate.longitude
        let waypointLat = waypoint.coordinate.latitude
        let waypointLong = waypoint.coordinate.longitude
        URLSession.shared.dataTask(with: RoadtripAPI.googleDirectionURL(originLat: originLat, originLong: originLong, destLat: destLat, destLong: destLong, waypointLat: waypointLat, waypointLong: waypointLong)) {
            (data, response, error) -> Void in
            let result = self.processDirectionsRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
            }.resume()
    }
    
    func getDistance(origin: CLLocation, destination: CLLocation, completion: @escaping (DistanceResult) -> Void) {
        let originLat = origin.coordinate.latitude
        let originLong = origin.coordinate.longitude
        let destLat = destination.coordinate.latitude
        let destLong = destination.coordinate.longitude
        URLSession.shared.dataTask(with: RoadtripAPI.googleDistanceMatrixURL(originLat: originLat, originLong: originLong, destinationLat: destLat, destinationLong: destLong)) {
            (data, response, error) -> Void in
            let result = self.processDistanceRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
            }.resume()
    }
    
    func getPlaceDetail(placeId: String, completion: @escaping (PlaceDetailResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.googlePlaceDetailURL(placeid: placeId)) {
            (data, response, error) -> Void in
            let result = self.processDetailRequest(data: data, error: error)
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
    
    private func processDistanceRequest(data: Data?, error: Error?) -> DistanceResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getDistanceResult(fromJSON: jsonData)
    }
    
    private func processDetailRequest(data: Data?, error: Error?) -> PlaceDetailResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getPlaceDetailResult(fromJSON: jsonData)
    }
    
}




