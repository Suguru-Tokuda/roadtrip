//
//  Trim.swift
//  roadtrip
//
//  Created by Suguru on 3/12/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import Foundation

public class Trim {
    
    private var _modelId: String?
    private var _modelMakeId: String?
    private var _modelName: String?
    private var _modelEngineFuel: String?
    private var _modelFuelCapG: Double?
    private var _mpgHwy: Int?
    private var _mpgCity: Int?
    private var _mpgMixed: Int?
    
    init(modelId: String, modelMakeId: String, modelName: String, modelEngingFule: String, modelFuelCapG: Double, mpgHwy: Int, mpgCity: Int, mpgMixed: Int) {
        _modelId = modelId
        _modelMakeId = modelMakeId
        _modelName = modelName
        _modelEngineFuel = modelEngingFule
        _modelFuelCapG = modelFuelCapG
        _mpgHwy = mpgHwy
        _mpgCity = mpgCity
        _mpgMixed = mpgMixed
    }
    
    public var modelId: String {
        get {
            return _modelId!
        }
        set(modelId) {
            _modelId = modelId
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
    
    public var modelName: String {
        get {
            return _modelName!
        }
        set(modelName) {
            _modelName = modelName
        }
    }
    
    public var modelEngineFuel: String {
        get {
            return _modelEngineFuel!
        }
        set(modelEngineFuel) {
            _modelEngineFuel = modelEngineFuel
        }
    }
    
    public var modelFuelCapG: Double {
        get {
            return _modelFuelCapG!
        }
        set(modelFuelCapG) {
            _modelFuelCapG = modelFuelCapG
        }
    }
    
    public var mpgHwy: Int {
        get {
            return _mpgHwy!
        }
        set(mpgHwy) {
            _mpgHwy = mpgHwy
        }
    }
    
    public var mpgCity: Int {
        get {
            return _mpgCity!
        }
        set(mpgCity) {
            _mpgCity = mpgCity
        }
    }
    
    public var mpgMixed: Int {
        get {
            return _mpgMixed!
        }
        set(mpgMixed) {
            _mpgMixed = mpgMixed
        }
    }
    
}
