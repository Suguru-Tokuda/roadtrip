//
//  ResponseModels.swift
//  roadtrip
//
//  Created by sanket bhat on 3/11/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

struct GooglePlacesResponse : Codable {
    let nextpagetoken : String?
    let results : [Place]
    enum CodingKeys : String, CodingKey {
        case nextpagetoken = "next_page_token"
        case results = "results"
    }
}

struct Place : Codable {
    
    let geometry : Location
    let name : String
    let openingHours : OpenNow?
    let photos : [PhotoInfo]?
    let types : [String]
    let address : String
    
    enum CodingKeys : String, CodingKey {
        case geometry = "geometry"
        case name = "name"
        case openingHours = "opening_hours"
        case photos = "photos"
        case types = "types"
        case address = "vicinity"
    }
    
    struct Location : Codable {
        
        let location : LatLong
        
        enum CodingKeys : String, CodingKey {
            case location = "location"
        }
        
        struct LatLong : Codable {
            
            let latitude : Double
            let longitude : Double
            
            enum CodingKeys : String, CodingKey {
                case latitude = "lat"
                case longitude = "lng"
            }
        }
    }
    
    struct OpenNow : Codable {
        
        let isOpen : Bool?
        
        enum CodingKeys : String, CodingKey {
            case isOpen = "open_now"
        }
    }
    
    struct PhotoInfo : Codable {
        
        let height : Int
        let width : Int
        let photoReference : String
        
        enum CodingKeys : String, CodingKey {
            case height = "height"
            case width = "width"
            case photoReference = "photo_reference"
        }
    }
}
