//
//  Years.swift
//  roadtrip
//
//  Created by Suguru on 3/11/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public struct YearsResponse : Codable {
    let years : Years?
}

public struct Years : Codable {
    
    let minYear : String?
    let maxYear : String?
    
    enum CodingKeys : String, CodingKey {
        case minYear = "min_year"
        case maxYear = "max_year"
    }
    
}
