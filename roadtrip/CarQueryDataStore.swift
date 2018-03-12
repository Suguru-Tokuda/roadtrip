//
//  CarQueryDataStore.swift
//  roadtrip
//
//  Created by Suguru on 3/11/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

enum YearsResult {
    case success([Int])
    case failure(Error)
}

public class CarQueryDataStore {
    
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func getYears(completion: @escaping (YearsResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.carQueryURL(method: .years, parameter: "")) {
            (data, response, error) -> Void in
            var jsonAsString = String(data: data!, encoding: .utf8)
            let start = jsonAsString!.index(jsonAsString!.startIndex, offsetBy: 2)
            let end = jsonAsString!.index(jsonAsString!.endIndex, offsetBy: -2)
            let range = start..<end
            jsonAsString = String(jsonAsString![range])
                let jsonData = jsonAsString!.data(using: .utf8)!
                let result = self.processYearsRequest(data: jsonData, error: error)
                OperationQueue.main.addOperation {
                    completion(result)
                }
        }.resume()
    }
    
    private func processYearsRequest(data: Data?, error: Error?) -> YearsResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getYearsResult(fromJSON: jsonData)
    }
    
}
