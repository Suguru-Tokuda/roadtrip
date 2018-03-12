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
    
    public static func googleAPIURL(method: GoogleAPIMethod, parameter: String) -> URL {
        let urlString = googleAPIURL + method.rawValue + parameter
        let url = URL(string: urlString)
        return url!
    }
    
    public static func getYearsResult(fromJSON data: Data) -> YearsResult {
        let decoder = JSONDecoder()
        var yearsResponse: YearsResponse?
        var years: [Int] = [Int]()
        do {
            yearsResponse = try decoder.decode(YearsResponse.self, from: data)
            let yearMax = Int(yearsResponse!.years!.maxYear!)
            let yearMin = Int(yearsResponse!.years!.minYear!)
            var year = yearMin
            while year != yearMax {
                years.append(year!)
                year! += 1
            }
            return .success(years)
        } catch let jsonDecoderError {
            print(jsonDecoderError)
            return .failure(jsonDecoderError)
        }
    }
    
}
