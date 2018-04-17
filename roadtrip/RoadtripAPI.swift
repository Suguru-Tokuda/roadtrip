//
//  APIs.swift
//  roadtrip
//
//  Created by Suguru on 3/10/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps

enum CarQueryMethod: String {
    case years = "getYears"
    case makes = "getMakes&year="
}

enum GoogleAPIMethod: String {
    case sample = "sample"
}

struct RoadtripAPI {

    private static let carQueryBaseURL = "https://www.carqueryapi.com/api/0.3/?&cmd="
    private static let myGasFeedBaseURL = "http://api.mygasfeed.com/stations/radius/"
    private static let googleAPIBaseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
    private static let googleDirectionsAPIBaseURL = "https://maps.googleapis.com/maps/api/directions/json?"
    private static let googleDistanceMatrixAPIBaseURL = "https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&"
    private static let googlePlaceDetailBaseURL = "https://maps.googleapis.com/maps/api/place/details/json?"
    private static let googlePhotoBaseURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400"

    public static let myGasFeedAPIKey = "3gi91gd4i1"
//    public static let googleMapsAPIKey = "AIzaSyDEdKM_L4ArIhHSyZdOImGpmAWArGT8W38"
    public static let googleMapsAPIKey = "AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg"
    public static let googleDirectionsAPIKey = "AIzaSyB5MtWNCa49FD9dSqC0iXd5JA4Vl-_Rf-c"
//    public static let googlePlacesAPIKey = "AIzaSyD96g2BYcVjnEstQLSXrOQ9kGQ1IqWq9wI"
    public static let googlePlacesAPIKey = "AIzaSyA3ElVIlEfP3sgehniZx3Aju7dpZDwRz6A"
    public static let googleDistanceMatrixAPI = "AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg"

    public static func carQueryURL(method: CarQueryMethod, parameter: String) -> URL {
        let urlString = carQueryBaseURL + method.rawValue + parameter
        let url = URL(string: urlString)
        return url!
    }
    
    public static func carQueryModelURL(make: String, year: String) -> URL {
        let makeStr = make.replacingOccurrences(of: " ", with: "")
        let urlString = "\(carQueryBaseURL)getModels&make=\(makeStr)&year=\(year)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func carQueryTrimURL(model: String, year: String) -> URL {
        let modelStr = model.replacingOccurrences(of: " ", with: "")
        let urlString = "\(carQueryBaseURL)getTrims&model=\(modelStr)&year=\(year)"
        let url = URL(string: urlString)
        return url!
    }
    
    // http://api.mygasfeed.com/stations/radius/40.4842/-88.9937/10/reg/price/3gi91gd4i1.json
    public static func myGasFeedURL(latitude: Double, longitude: Double, distance: Double, gasType: String) -> URL {
        let urlString = "\(myGasFeedBaseURL)\(latitude)/\(longitude)/\(distance)/\(gasType)/price/\(myGasFeedAPIKey).json"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googlePlacesDataURL(location: CLLocation, keyword: String, radius: Int, token: String) -> URL {
        let locationString = "location=" + String(location.coordinate.latitude) + "," + String(location.coordinate.longitude)
        let radiusstr = "radius=\(radius)"
        let rankby = "rankby=prominence"
//        let rankby = "rankby=distance"
        let keywrd = "keyword=" + keyword
        let key = "key=" + googleMapsAPIKey
        let pagetoken = "pagetoken="+token
        return URL(string: googleAPIBaseURL + locationString + "&" + radiusstr + "&" + rankby + "&" + keywrd + "&" + key + "&" + pagetoken)!
//        return URL(string: googleAPIBaseURL + locationString + "&" + rankby + "&" + keywrd + "&" + key + "&" + pagetoken)!
    }
    
    public static func googleDirectionURL(originLat: Double, originLong: Double, destLat: Double, destLong: Double) -> URL {
        let urlString = "\(googleDirectionsAPIBaseURL)origin=\(originLat),\(originLong)&destination=\(destLat),\(destLong)&key=\(googleDirectionsAPIKey)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googlePlaceDetailURL(placeid: String) -> URL {
        let urlString = "\(googlePlaceDetailBaseURL)placeid=\(placeid)&key=\(googlePlacesAPIKey)"
        print(urlString)
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googleDirectionURL(originLat: Double, originLong: Double, destLat: Double, destLong: Double, waypointLat: Double, waypointLong: Double) -> URL {
        let urlString = "\(googleDirectionsAPIBaseURL)origin=\(originLat),\(originLong)&destination=\(destLat),\(destLong)&waypoints=via:\(waypointLat)%2C\(waypointLong)&key=\(googleDirectionsAPIKey)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googleDirectionURL(originId: String, destinationId: String) -> URL {
        let urlString = "\(googleDirectionsAPIBaseURL)origin=place_id:\(originId)&destination=place_id:\(destinationId)&key=\(googleDirectionsAPIKey)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googleDistanceMatrixURL(originLat: Double, originLong: Double, destinationLat: Double, destinationLong: Double) -> URL {
        let urlString = "\(googleDistanceMatrixAPIBaseURL)origins=\(originLat),\(originLong)&destinations=\(destinationLat),\(destinationLong)&key=\(googleDistanceMatrixAPI)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func googlePhotoURL(photoReference: String) -> URL {
        let urlString = "\(googlePhotoBaseURL)&photoreference=\(photoReference)&key=\(googlePlacesAPIKey)"
        let url = URL(string: urlString)
        return url!
    }
    
    public static func getGasPricesResult(fromJSON data: Data) -> GasPricesResult {
        do {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            let gasStations = try jsonDecoder.decode(GasStations.self, from: data)
            return .success(gasStations)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
    public static func getYearsResult(fromJSON data: Data) -> YearsResult {
        var maxYear: Int?
        var minYear: Int?
        
        var yearsArray: [Int] = [Int]()
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            if let years = jsonObject as? [AnyHashable: Any] {
                if let nestedYears = years["Years"] as? [String: Any] {
                    maxYear = Int(nestedYears["max_year"]! as? String ?? "")
                    minYear = Int(nestedYears["min_year"]! as? String ?? "")
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
                        let makeDisplay = make["make_display"] as? String ?? ""
                        let makeCountry = make["make_country"] as? String ?? ""
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
                        let modelName = model["model_name"] as? String ?? ""
                        let modelMakeId = model["model_make_id"] as? String ?? ""
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
                        if trim["model_trim"] as! String != "" {
                            let modelId = trim["model_id"] as? String ?? ""
                            let modelMakeId = trim["model_make_id"] as? String ?? ""
                            let modelName = trim["model_name"] as? String ?? ""
                            let modelTrim = trim["model_trim"] as? String ?? ""
                            let modelEngineFuel = trim["model_engine_fuel"] as? String ?? ""
                            var modelFuelCapG: Double?
                            if trim["model_fuel_cap_g"] as? String != nil {
                                modelFuelCapG = Double(trim["model_fuel_cap_g"] as! String)
                            } else {
                                modelFuelCapG = Double(trim["model_fuel_cap_l"] as? String ?? "0")! / 3.78541
                            }
                            var mpgHwy: Double?
                            var mpgCity: Double?
                            var mpgMixed: Double?
                            if trim["mpg_hwy"] as? String == nil {
                                mpgHwy = 100 / Double(trim["model_lkm_hwy"] as? String ?? "0")! / 1.609 * 3.785
                            } else {
                                mpgHwy = Double(trim["mpg_hwy"] as! String)!
                            }
                            if trim["mpg_city"] as? String == nil {
                                mpgCity = 100 / Double(trim["model_lkm_city"] as? String ?? "0")! / 1.609 * 3.785
                            } else {
                                mpgCity = Double(trim["mpg_city"] as! String)
                            }
                            if trim["mpg_mix"] as? String == nil {
                                mpgMixed = 100 / Double(trim["model_lkm_mix"] as? String ?? "0")! / 1.609 * 3.785
                            } else {
                                mpgMixed = Double(trim["mpg_mix"] as! String)
                            }
                            let tempTrim = Trim(modelId: modelId, modelMakeId: modelMakeId, modelName: modelName, modelTrim: modelTrim, modelEngingFule: modelEngineFuel, modelFuelCapG: modelFuelCapG!, mpgHwy: mpgHwy!, mpgCity: mpgCity!, mpgMixed: mpgMixed!)
                            if (tempTrim.mpgHwy != Double.infinity) {
                                trimsArray.append(tempTrim)
                            }
                        }
                    }
                }
            }
            return .success(trimsArray)
        } catch let jsonError {
            return .failure(jsonError)
        }
    }
    
    public static func getDirectionsResult(fromJSON data: Data) -> DirectionsResult {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(Direction.self, from: data)
            return .success(response)
        } catch let jsonDecoderError {
            return .failure(jsonDecoderError)
        }
    }
    
    public static func getDistanceResult(fromJSON data: Data) -> DistanceResult {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let response = try decoder.decode(Distance.self, from: data)
            return .success(response)
        } catch let jsonDecoderError {
            return .failure(jsonDecoderError)
        }
    }
    
    public static func getPlaceDetailResult(fromJSON data: Data) -> PlaceDetailResult {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(PlaceDetail.self, from: data)
            return .success(response)
        } catch let jsonDecoderError {
            return .failure(jsonDecoderError)
        }
    }
        
}
