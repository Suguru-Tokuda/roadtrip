//
//  PlaceDetailsDataStore.swift
//  roadtrip
//
//  Created by sanket bhat on 4/14/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

struct PlaceDetail : Codable {
    let htmlattributions : [String]?
    let result : Result?
    let status : String?
    
    enum CodingKeys: String, CodingKey {
        
        case htmlattributions = "html_attributions"
        case result = "result"
        case status = "status"
    }

    struct Result : Codable {
        let addresscomponents : [Addresscomponents]?
        let adraddress : String?
        let formattedaddress : String?
        let formattedphonenumber : String?
        let geometry : Geometry?
        let icon : String?
        let id : String?
        let internationalphonenumber : String?
        let name : String?
        let openinghours : Openinghours?
        let photos : [Photos]?
        let placeid : String?
        let rating : Double?
        let reference : String?
        let reviews : [Reviews]?
        let scope : String?
        let types : [String]?
        let url : String?
        let utcoffset : Double?
        let vicinity : String?
        let website : String?
        
        enum CodingKeys: String, CodingKey {
            
            case addresscomponents = "address_components"
            case adraddress = "adr_address"
            case formattedaddress = "formatted_address"
            case formattedphonenumber = "formatted_phone_number"
            case geometry
            case icon = "icon"
            case id = "id"
            case internationalphonenumber = "international_phone_number"
            case name = "name"
            case openinghours = "opening_hours"
            case photos = "photos"
            case placeid = "place_id"
            case rating = "rating"
            case reference = "reference"
            case reviews = "reviews"
            case scope = "scope"
            case types = "types"
            case url = "url"
            case utcoffset = "utc_offset"
            case vicinity = "vicinity"
            case website = "website"
        }
        
        struct Addresscomponents : Codable {
            let longname : String?
            let shortname : String?
            let types : [String]?
            
            enum CodingKeys: String, CodingKey {
                
                case longname = "long_name"
                case shortname = "short_name"
                case types = "types"
            }
            
        }
        struct Reviews : Codable {
            let authorname : String?
            let authorurl : String?
            let language : String?
            let profilephotourl : String?
            let rating : Int?
            let relativetimedescription : String?
            let text : String?
            let time : Int?
            
            enum CodingKeys: String, CodingKey {
                
                case authorname = "author_name"
                case authorurl = "author_url"
                case language = "language"
                case profilephotourl = "profile_photo_url"
                case rating = "rating"
                case relativetimedescription = "relative_time_description"
                case text = "text"
                case time = "time"
            }
            
            
        }
        
        struct Photos : Codable {
            let height : Int?
            let htmlattributions : [String]?
            let photoreference : String?
            let width : Int?
            
            enum CodingKeys: String, CodingKey {
                
                case height = "height"
                case htmlattributions = "html_attributions"
                case photoreference = "photo_reference"
                case width = "width"
            }
            
        }

        struct Openinghours : Codable {
            let opennow : Bool?
            let periods : [Periods]?
            let weekdaytext : [String]?
            
            enum CodingKeys: String, CodingKey {
                
                case opennow = "open_now"
                case periods = "periods"
                case weekdaytext = "weekday_text"
            }
            struct Periods : Codable {
                let open : Open?
                
                enum CodingKeys: String, CodingKey {
                    
                    case open
                }
                struct Open : Codable {
                    let day : Int?
                    let time : String?
                    
                    enum CodingKeys: String, CodingKey {
                        
                        case day = "day"
                        case time = "time"
                    }
                    
                }

            }
            
        }
        struct Geometry : Codable {
            let location : Location?
            let viewport : Viewport?
            
            enum CodingKeys: String, CodingKey {
                
                case location
                case viewport
            }
            struct Location : Codable {
                let lat : Double?
                let lng : Double?
                
                enum CodingKeys: String, CodingKey {
                    
                    case lat = "lat"
                    case lng = "lng"
                }
                
                
            }
            
            struct Viewport : Codable {
                let northeast : Northeast?
                let southwest : Southwest?
                
                enum CodingKeys: String, CodingKey {
                    
                    case northeast
                    case southwest
                }
                struct Northeast : Codable {
                    let lat : Double?
                    let lng : Double?
                    
                    enum CodingKeys: String, CodingKey {
                        
                        case lat = "lat"
                        case lng = "lng"
                    }
                    
                }
                struct Southwest : Codable {
                    let lat : Double?
                    let lng : Double?
                    
                    enum CodingKeys: String, CodingKey {
                        
                        case lat = "lat"
                        case lng = "lng"
                    }
                    
                }
            }
            
            
        }
    }

}









