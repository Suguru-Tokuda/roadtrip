//
//  APIs.swift
//  roadtrip
//
//  Created by Suguru on 3/10/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

enum CarQueryMethod: String {
    case years = "getYears"
    case makes = "getMakes&year="
}

enum GoogleAPIMethod: String {
    case sample = "sample"
}

struct RoadtripAPI {
    
    private static let carQueryBaseURL = "https://www.carqueryapi.com/api/0.3/?callback=?&cmd="
    private static let googleAPIURL = ""
    
    public static func carQueryURL(method: CarQueryMethod, parameter: String) -> URL {
        let urlString = carQueryBaseURL + method.rawValue + parameter
        let url = URL(string: urlString)
        return url!
    }
    
    public static func carQueryModelURL(make: String, year: String) -> URL {
        let urlString = "\(carQueryBaseURL)getModel&make=\(make)&year=\(year)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func carQueryTrimURL(model: String, year: String) -> URL {
        let urlString = "\(carQueryBaseURL)getTrims&model=\(model)&year=\(year)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googleAPIURL(method: GoogleAPIMethod, parameter: String) -> URL {
        let urlString = googleAPIURL + method.rawValue + parameter
        let url = URL(string: urlString)
        return url!
    }
    
    public static func getYearsResult(fromJSON data: Data) -> YearsResult {
        var maxYear: Int?
        var minYear: Int?
        
        var yearsArray: [Int] = [Int]()
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let years = jsonObject as? [AnyHashable: Any] {
                if let nestedYears = years["Years"] as? [String: Any] {
                    maxYear = Int(nestedYears["max_year"]! as! String)
                    minYear = Int(nestedYears["min_year"]! as! String)
                }
            }
            var year = minYear
            while year != maxYear {
                yearsArray.append(year!)
                year! += 1
            }
            return .success(yearsArray)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
    public static func getMakesResult(fromJSON data: Data) -> MakesResult {
        var makesArray: [Make] = [Make]()
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArray = jsonObject as? [AnyHashable: Any] {
                if let makes = jsonArray["Makes"] as? [[String: Any]] {
                    for make in makes {
                        let makeDisplay = make["make_display"] as! String
                        let makeCountry = make["make_country"] as! String
                        let tempMake = Make(makeDisplay: makeDisplay, makeCountry: makeCountry)
                        makesArray.append(tempMake)
                    }
                }
            }
            return .success(makesArray)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
    public static func getModelsResult(fromJSON data: Data) -> ModelsResult {
        var modelsArray: [Model] = [Model]()
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArray = jsonObject as? [AnyHashable: Any] {
                if let models = jsonArray["Models"] as? [[String: Any]] {
                    for model in models {
                        let modelName = model["model_name"] as! String
                        let modelMakeId = model["model_make_id"] as! String
                        let tempModel = Model(modelName: modelName, modelMakeId: modelMakeId)
                        modelsArray.append(tempModel)
                    }
                }
            }
            return .success(modelsArray)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
    public static func getTrimsResult(fromJSON data: Data) -> TrimsResult {
        var trimsArray: [Trim] = [Trim]()
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArray = jsonObject as? [AnyHashable: Any] {
                if let trims = jsonArray["Trims"] as? [[String: Any]] {
                    for trim in trims {
                        let modelId = trim["model_id"] as! String
                        let modelMakeId = trim["model_makde_Id"] as! String
                        let modelName = trim["model_name"] as! String
                        let modelEngineFuel = trim["model_engine_fule"] as! String
                        let modelFuleCapG = Double(trim["model_fule_cap_g"] as! String)
                        let mpgHwy = Int(trim["mpg_hwy"] as! String)
                        let mpgCity = Int(trim["mpg_city"] as! String)
                        let mpgMixed = Int(trim["mpg_mix"] as! String)
                        let tempTrim = Trim(modelId: modelId, modelMakeId: modelMakeId, modelName: modelName, modelEngingFule: modelEngineFuel, modelFuelCapG: modelFuleCapG!, mpgHwy: mpgHwy!, mpgCity: mpgCity!, mpgMixed: mpgMixed!)
                        trimsArray.append(tempTrim)
                    }
                }
            }

            return .success(trimsArray)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
}
