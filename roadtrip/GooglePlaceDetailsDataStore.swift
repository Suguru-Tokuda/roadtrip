//
//  PlaceDetailsDataStore.swift
//  roadtrip
//
//  Created by sanket bhat on 4/14/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

struct PlaceDetail : Codable {
    let html_attributions : [String]?
    let result : Result?
    let status : String?
    
    enum CodingKeys: String, CodingKey {
        
        case html_attributions = "html_attributions"
        case result
        case status = "status"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        html_attributions = try values.decodeIfPresent([String].self, forKey: .html_attributions)
        result = try Result(from: decoder)
        status = try values.decodeIfPresent(String.self, forKey: .status)
    }
    
}

struct Result : Codable {
    let address_components : [Address_components]?
    let adr_address : String?
    let formatted_address : String?
    let formatted_phone_number : String?
    let geometry : Geometry?
    let icon : String?
    let id : String?
    let international_phone_number : String?
    let name : String?
    let opening_hours : Opening_hours?
    let photos : [Photos]?
    let place_id : String?
    let rating : Int?
    let reference : String?
    let reviews : [Reviews]?
    let scope : String?
    let types : [String]?
    let url : String?
    let utc_offset : Int?
    let vicinity : String?
    let website : String?
    
    enum CodingKeys: String, CodingKey {
        
        case address_components = "address_components"
        case adr_address = "adr_address"
        case formatted_address = "formatted_address"
        case formatted_phone_number = "formatted_phone_number"
        case geometry
        case icon = "icon"
        case id = "id"
        case international_phone_number = "international_phone_number"
        case name = "name"
        case opening_hours
        case photos = "photos"
        case place_id = "place_id"
        case rating = "rating"
        case reference = "reference"
        case reviews = "reviews"
        case scope = "scope"
        case types = "types"
        case url = "url"
        case utc_offset = "utc_offset"
        case vicinity = "vicinity"
        case website = "website"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        address_components = try values.decodeIfPresent([Address_components].self, forKey: .address_components)
        adr_address = try values.decodeIfPresent(String.self, forKey: .adr_address)
        formatted_address = try values.decodeIfPresent(String.self, forKey: .formatted_address)
        formatted_phone_number = try values.decodeIfPresent(String.self, forKey: .formatted_phone_number)
        geometry = try Geometry(from: decoder)
        icon = try values.decodeIfPresent(String.self, forKey: .icon)
        id = try values.decodeIfPresent(String.self, forKey: .id)
        international_phone_number = try values.decodeIfPresent(String.self, forKey: .international_phone_number)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        opening_hours = try Opening_hours(from: decoder)
        photos = try values.decodeIfPresent([Photos].self, forKey: .photos)
        place_id = try values.decodeIfPresent(String.self, forKey: .place_id)
        rating = try values.decodeIfPresent(Int.self, forKey: .rating)
        reference = try values.decodeIfPresent(String.self, forKey: .reference)
        reviews = try values.decodeIfPresent([Reviews].self, forKey: .reviews)
        scope = try values.decodeIfPresent(String.self, forKey: .scope)
        types = try values.decodeIfPresent([String].self, forKey: .types)
        url = try values.decodeIfPresent(String.self, forKey: .url)
        utc_offset = try values.decodeIfPresent(Int.self, forKey: .utc_offset)
        vicinity = try values.decodeIfPresent(String.self, forKey: .vicinity)
        website = try values.decodeIfPresent(String.self, forKey: .website)
    }
    
}

struct Address_components : Codable {
    let long_name : Int?
    let short_name : Int?
    let types : [String]?
    
    enum CodingKeys: String, CodingKey {
        
        case long_name = "long_name"
        case short_name = "short_name"
        case types = "types"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        long_name = try values.decodeIfPresent(Int.self, forKey: .long_name)
        short_name = try values.decodeIfPresent(Int.self, forKey: .short_name)
        types = try values.decodeIfPresent([String].self, forKey: .types)
    }
    
}

struct Geometry : Codable {
    let location : Location?
    let viewport : Viewport?
    
    enum CodingKeys: String, CodingKey {
        
        case location
        case viewport
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        location = try Location(from: decoder)
        viewport = try Viewport(from: decoder)
    }
    
}


struct Location : Codable {
    let lat : Double?
    let lng : Double?
    
    enum CodingKeys: String, CodingKey {
        
        case lat = "lat"
        case lng = "lng"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        lng = try values.decodeIfPresent(Double.self, forKey: .lng)
    }
    
}

struct Viewport : Codable {
    let northeast : Northeast?
    let southwest : Southwest?
    
    enum CodingKeys: String, CodingKey {
        
        case northeast
        case southwest
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        northeast = try Northeast(from: decoder)
        southwest = try Southwest(from: decoder)
    }
    
}

struct Open : Codable {
    let day : Int?
    let time : Int?
    
    enum CodingKeys: String, CodingKey {
        
        case day = "day"
        case time = "time"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        day = try values.decodeIfPresent(Int.self, forKey: .day)
        time = try values.decodeIfPresent(Int.self, forKey: .time)
    }
    
}
struct Opening_hours : Codable {
    let open_now : Bool?
    let periods : [Periods]?
    let weekday_text : [String]?
    
    enum CodingKeys: String, CodingKey {
        
        case open_now = "open_now"
        case periods = "periods"
        case weekday_text = "weekday_text"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        open_now = try values.decodeIfPresent(Bool.self, forKey: .open_now)
        periods = try values.decodeIfPresent([Periods].self, forKey: .periods)
        weekday_text = try values.decodeIfPresent([String].self, forKey: .weekday_text)
    }
    
}
struct Photos : Codable {
    let height : Int?
    let html_attributions : [String]?
    let photo_reference : String?
    let width : Int?
    
    enum CodingKeys: String, CodingKey {
        
        case height = "height"
        case html_attributions = "html_attributions"
        case photo_reference = "photo_reference"
        case width = "width"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        height = try values.decodeIfPresent(Int.self, forKey: .height)
        html_attributions = try values.decodeIfPresent([String].self, forKey: .html_attributions)
        photo_reference = try values.decodeIfPresent(String.self, forKey: .photo_reference)
        width = try values.decodeIfPresent(Int.self, forKey: .width)
    }
    
}
struct Reviews : Codable {
    let author_name : String?
    let author_url : String?
    let language : String?
    let profile_photo_url : String?
    let rating : Int?
    let relative_time_description : String?
    let text : String?
    let time : Int?
    
    enum CodingKeys: String, CodingKey {
        
        case author_name = "author_name"
        case author_url = "author_url"
        case language = "language"
        case profile_photo_url = "profile_photo_url"
        case rating = "rating"
        case relative_time_description = "relative_time_description"
        case text = "text"
        case time = "time"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        author_name = try values.decodeIfPresent(String.self, forKey: .author_name)
        author_url = try values.decodeIfPresent(String.self, forKey: .author_url)
        language = try values.decodeIfPresent(String.self, forKey: .language)
        profile_photo_url = try values.decodeIfPresent(String.self, forKey: .profile_photo_url)
        rating = try values.decodeIfPresent(Int.self, forKey: .rating)
        relative_time_description = try values.decodeIfPresent(String.self, forKey: .relative_time_description)
        text = try values.decodeIfPresent(String.self, forKey: .text)
        time = try values.decodeIfPresent(Int.self, forKey: .time)
    }
    
}
struct Periods : Codable {
    let open : Open?
    
    enum CodingKeys: String, CodingKey {
        
        case open
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        open = try Open(from: decoder)
    }
    
}
struct Northeast : Codable {
    let lat : Double?
    let lng : Double?
    
    enum CodingKeys: String, CodingKey {
        
        case lat = "lat"
        case lng = "lng"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        lng = try values.decodeIfPresent(Double.self, forKey: .lng)
    }
    
}
struct Southwest : Codable {
    let lat : Double?
    let lng : Double?
    
    enum CodingKeys: String, CodingKey {
        
        case lat = "lat"
        case lng = "lng"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decodeIfPresent(Double.self, forKey: .lat)
        lng = try values.decodeIfPresent(Double.self, forKey: .lng)
    }
    
}
