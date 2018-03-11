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
    
}

struct RoatripAPI {
    
    private static let carQueryBaseURL = "https://www.carqueryapi.com/api/0.3/?callback=?cmd"
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
    
}
