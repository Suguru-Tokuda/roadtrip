//
//  Model.swift
//  roadtrip
//
//  Created by Suguru on 3/12/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public class Model {
    
    private var _modelName: String?
    private var _modelMakeId: String?
    
    init(modelName: String, modelMakeId: String) {
        _modelName = modelName
        _modelMakeId = modelMakeId
    }
    
    public var modelName: String {
        get {
            return _modelName!
        }
        set(modelName) {
            _modelName = modelName
        }
    }    
    
    public var modelMakeId: String {
        get {
            return _modelMakeId!
        }
        set(modelMakeId) {
            _modelMakeId = modelMakeId
        }
    }
    
}
