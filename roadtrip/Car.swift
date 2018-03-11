import Foundation
import CoreData

public class Car {
    
    private var _make: String?
    private var _model: String?
    private var _trim: String?
    private var _year: String?
    private var _millage: Double?
    private var _gasType: String?
    private var _mpg: Double?
    
    // MARK: Initializer
    public init(make: String, model: String, trim: String, year: String, millage: Double, gasType: String, mpg: Double) {
        self._make = make
        self._model = model
        self._trim = trim
        self._year = year
        self._millage = millage
        self._gasType = gasType
        self._mpg = mpg
    }
    
    // MARK: Getters & Setters
    public var make: String {
        get {
            return self._make!
        }
        set(make) {
            self._make = make
        }
    }
    
    public var model: String {
        get {
            return self._model!
        }
        set(model) {
            self._model = model
        }
    }
    
    public var trim: String {
        get {
            return self._trim!
        }
        set(trim) {
            self._trim = trim
        }
    }
    
    public var year: String {
        get {
            return self._year!
        }
        set(year) {
            self._year = year
        }
    }
    
    public var millage: Double {
        get {
            return self._millage!
        }
        set(millage) {
            self._millage = millage
        }
    }
    
    public var gasType: String {
        get {
            return self._gasType!
        }
        set(gasType) {
            self._gasType = gasType
        }
    }
    
    public var mpg: Double {
        get {
            return self._mpg!
        }
        set(mpg) {
            self._mpg = mpg
        }
    }
    
}
