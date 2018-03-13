//
//  Make.swift
//  roadtrip
//
//  Created by Suguru on 3/12/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public class Make {
    
    private var _makeDisplay: String?
    private var _makeCountry: String?
    
    init(makeDisplay: String, makeCountry: String?) {
        _makeDisplay = makeDisplay
        _makeCountry = makeCountry
    }
    
    public var makeDisplay: String {
        get {
            return _makeDisplay!
        }
        set(makeDisplay) {
            _makeDisplay = makeDisplay
        }
    }
    
    public var makeCountry: String {
        get {
            return _makeCountry!
        }
        set(makeCountry) {
            _makeCountry = makeCountry
        }
    }
    
}
