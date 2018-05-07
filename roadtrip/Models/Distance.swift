//
//  Distance.swift
//  roadtrip
//
//  Created by Suguru on 4/6/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public struct Distance: Codable {
    
    var originAddresses: [String]?
    var destinationAddresses: [String]?
    var rows: [Row]?
    
    struct Row: Codable {
        
        var elements: [Elements]?
        
        struct Elements: Codable {
            
            var duration: Duration?
            var distance: Distance?
            
            struct Duration: Codable {
                var value: Double?
                var text: String?
            }
            
            struct Distance: Codable {
                var value: Double?
                var text: String?
            }
        }
    }
    
}
