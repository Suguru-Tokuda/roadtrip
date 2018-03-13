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

enum MakesResult {
    case success([Make])
    case failure(Error)
}

enum ModelsResult {
    case success([Model])
    case failure(Error)
}

enum TrimsResult {
    case success([Trim])
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
    
    func getMakes(year: Int, completion: @escaping (MakesResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.carQueryURL(method: .makes, parameter: String(year))) {
            (data, response, error) -> Void in
            var jsonAsString = String(data: data!, encoding: .utf8)
            let start = jsonAsString!.index(jsonAsString!.startIndex, offsetBy: 2)
            let end = jsonAsString!.index(jsonAsString!.endIndex, offsetBy: -2)
            let range = start..<end
            jsonAsString = String(jsonAsString![range])
            let jsonData = jsonAsString!.data(using: .utf8)!
            let result = self.processMakesResult(data: jsonData, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }.resume()
    }
    
    func getModels(make: String, year: Int, completion: @escaping (ModelsResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.carQueryModelURL(make: make, year: String(year))) {
            (data, response, error) -> Void in
            var jsonAsString = String(data: data!, encoding: .utf8)
            let start = jsonAsString!.index(jsonAsString!.startIndex, offsetBy: 2)
            let end = jsonAsString!.index(jsonAsString!.endIndex, offsetBy: -2)
            let range = start..<end
            jsonAsString = String(jsonAsString![range])
            let jsonData = jsonAsString!.data(using: .utf8)!
            let result = self.processModelsResult(data: jsonData, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }.resume()
    }
    
    func getTrims(model: String, year: Int, completion: @escaping (TrimsResult) -> Void) {
        URLSession.shared.dataTask(with: RoadtripAPI.carQueryTrimURL(model: model, year: String(year))) {
            (data, response, error) -> Void in
            var jsonAsString = String(data: data!, encoding: .utf8)
            let start = jsonAsString!.index(jsonAsString!.startIndex, offsetBy: 2)
            let end = jsonAsString!.index(jsonAsString!.endIndex, offsetBy: -2)
            let range = start..<end
            jsonAsString = String(jsonAsString![range])
            let jsonData = jsonAsString!.data(using: .utf8)!
            let result = self.processTrimsResult(data: jsonData, error: error)
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
    
    private func processMakesResult(data: Data?, error: Error?) -> MakesResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getMakesResult(fromJSON: jsonData)
    }
    
    private func processModelsResult(data: Data?, error: Error?) -> ModelsResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getModelsResult(fromJSON: jsonData)
    }
    
    private func processTrimsResult(data: Data?, error: Error?) -> TrimsResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return RoadtripAPI.getTrimsResult(fromJSON: jsonData)
    }
    
}
