//
//  PlaceMarker.swift
//  roadtrip
//
//  Created by sanket bhat on 3/10/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class PlaceMarker: GMSMarker {
    let place: Place
    
    init(place: Place) {
        self.place = place
        super.init()
        position = CLLocationCoordinate2DMake(place.geometry.location.latitude, place.geometry.location.longitude)
        var foundType = "bar"
        //let possibleTypes = acceptedTypes.count > 0 ? acceptedTypes : ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
        let possibleTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
        
        
        if let types = place.types as? [String] {
            for type in types {
                if possibleTypes.contains(type) {
                    foundType = type
                    break
                }
            }
        }
        
        icon = UIImage(named: foundType+"_pin")
        groundAnchor = CGPoint(x: 0.5, y: 1)
        appearAnimation = .pop
    }

}

