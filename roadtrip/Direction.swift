//
//  Direction.swift
//  roadtrip
//
//  Created by Suguru on 3/18/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public struct Direction: Codable {
    
    var routes: [Route]
    
    public struct Route: Codable {
        
        var legs: [Leg]?
        var bounds: Bounds?
        
        public struct Leg: Codable {
            
            var distance: Distance?
            var duration: Duration?
            var startAddress: String?
            var startLocation: StartLocation?
            var endAddress: String?
            var endLocation: EndLocation?
            var steps: [Step]?
            var overviewPolyine: OverviewPolyline?
            var summary: String?
            
            enum CodingKeys: String, CodingKey {
                case distance
                case duration
                case startAddress = "start_address"
                case startLocation = "start_location"
                case endAddress = "end_address"
                case endLocation = "end_location"
                case steps
                case overviewPolyine = "overview_polyline"
                case summary
            }
            
            struct Distance: Codable {
                var text: String?
                var value: Int?
            }
            
            struct Duration: Codable {
                var text: String?
                var value: Int?
            }
            
            struct StartLocation: Codable {
                var lat: Double?
                var lng: Double?
            }
            
            struct EndLocation: Codable {
                var lat: Double?
                var lng: Double?
            }
            
            struct Step: Codable {
                
                enum CodingKeys: String, CodingKey {
                    case distance
                    case duration
                    case endLocation
                    case startLocation
                    case htmlInstructions
                    case maneuver
                    case polyLine
                    case travelMode
                }
                
                var distance: Distance?
                var duration: Duration?
                var endLocation: EndLocation?
                var startLocation: StartLocation?
                var htmlInstructions: String?
                var maneuver: String?
                var polyLine: Polyline?
                var travelMode: String?
                
                struct Distance: Codable {
                    var text: String?
                    var value: Int?
                }
                
                struct Duration: Codable {
                    var text: String?
                    var value: Int?
                }
                
                struct EndLocation: Codable {
                    var lat: Double?
                    var lng: Double?
                }
                
                struct Polyline: Codable {
                    var points: String?
                }
                
                struct StartLocation: Codable {
                    var lat: Double?
                    var lng: Double?
                }
            }
        }
        
        struct OverviewPolyline: Codable {
            var points: String?
        }
        
        struct Bounds: Codable {
            
            var northeast: Northeast?
            var southwest: Southwest?
            
            struct Northeast: Codable {
                var lat: Double?
                var lng: Double?
            }
            
            struct Southwest: Codable {
                var lat: Double?
                var lng: Double?
            }
        }
    }    
    
}

