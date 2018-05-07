//
//  GasPricesDataStore.swift
//  roadtrip
//
//  Created by Suguru on 4/8/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

enum GasPricesResult {
    case success(GasStations)
    case failure(Error)
}

public class GasPricesDataStore {
    
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func getGasPrices(latitude: Double, longitutde: Double, distanceInMiles: Double, gasType: String, completion: @escaping (GasPricesResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.myGasFeedURL(latitude: latitude, longitude: longitutde, distance: distanceInMiles, gasType: gasType)) {
            (data, response, error) -> Void in
            let result = self.processGasPricesRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
            }.resume()
    }
    
    private func processGasPricesRequest(data: Data?, error: Error?) -> GasPricesResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getGasPricesResult(fromJSON: jsonData)
    }
    
    
}
