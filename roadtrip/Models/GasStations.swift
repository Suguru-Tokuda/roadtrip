//
//  GasStations.swift
//  roadtrip
//
//  Created by Suguru on 4/8/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public struct GasStations: Codable {
    var stations: [Station]?
    
    public struct Station: Codable, Hashable {
        
        public var hashValue: Int{
            return Int(lat! * 100000000 + lng! * 100000000)
        }
        
        var country: String?
        var zip: String?
        var regPrice: Double?
        var midPrice: Double?
        var prePrice: Double?
        var dieselPrice: Double?
        var regDate: String?
        var midDate: String?
        var preDate: String?
        var address: String?
        var id: String?
        var lat: Double?
        var lng: Double?
        var station: String?
        var region: String?
        var city: String?
        var distance: String?
        
        enum CodkingKeys: String, CodingKey {
            case country
            case zip
            case regPrice = "reg_price"
            case midPrice = "mid_price"
            case prePrice = "pre_price"
            case dieselPrice = "diesel_price"
            case regDate = "reg_date"
            case midDate = "mid_date"
            case preDate = "pre_date"
            case address
            case id
            case lat
            case lng
            case station
            case region
            case city
            case distance
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.country = try container.decode(String.self, forKey: .country)
            self.zip = try container.decode(String.self, forKey: .zip)
            self.regPrice = try Double(container.decode(String.self, forKey: .regPrice))
            self.midPrice = try Double(container.decode(String.self, forKey: .midPrice))
            self.prePrice = try Double(container.decode(String.self, forKey: .prePrice))
            self.regDate = try container.decode(String.self, forKey: .regDate)
            self.midDate = try container.decode(String.self, forKey: .midDate)
            self.preDate = try container.decode(String.self, forKey: .preDate)
            self.address = try container.decode(String.self, forKey: .address)
            self.id = try container.decode(String.self, forKey: .id)
            self.lat = try Double(container.decode(String.self, forKey: .lat))
            self.lng = try Double(container.decode(String.self, forKey: .lng))
            self.station = try container.decode(String.self, forKey: .station)
            self.region = try container.decode(String.self, forKey: .region)
            self.city = try container.decode(String.self, forKey: .city)
            self.distance = try container.decode(String.self, forKey: .distance)
        }
        
    }
}
