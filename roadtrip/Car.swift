import Foundation
import CoreData

public class Car {
    
    private var _make: String?
    private var _model: String?
    private var _trim: String?
    private var _year: String?
    private var _fuelCapacity: Double?
    private var _gasType: String?
    private var _mpgHwy: Double?
    private var _mpgCity: Double?
    private var _fuelRemainingInPercent: Double?
    private var _fuelRemaining: Double?
    
    // MARK: Initializer
    public init(make: String, model: String, trim: String, year: String, fuelCapacity: Double, gasType: String, mpgHwy: Double, mpgCity: Double) {
        self._make = make
        self._model = model
        self._trim = trim
        self._year = year
        self._fuelCapacity = fuelCapacity
        self._gasType = gasType
        self._mpgHwy = mpgHwy
        self._mpgCity = mpgCity
        self._fuelRemainingInPercent = 100.0
        self._fuelRemaining = self._fuelCapacity
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
    
    public var fuelCapacity: Double {
        get {
            return round(1000 * self._fuelCapacity!) / 1000
        }
        set(fuelCapacity) {
            self._fuelCapacity = fuelCapacity
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
    
    public var mpgHwy: Double {
        get {
            return round(1000 * self._mpgHwy!) / 1000
        }
        set(mpgHwy) {
            self._mpgHwy = mpgHwy
        }
    }
    
    public var mpgCity: Double {
        get {
            return round(1000 * self._mpgCity!) / 1000
        }
        set(mpgCity) {
            self._mpgCity = mpgCity
        }
    }
    
    public var fuelRemainingInPercent: Double {
        get {
            return self._fuelRemainingInPercent!
        }
        set(fuelRemainingInPercent) {
            self._fuelRemainingInPercent = fuelRemainingInPercent
        }
    }
    
    public func getFuelRemaining() -> Double {
        return round(1000 * self._fuelCapacity! * _fuelRemainingInPercent! / 100) / 1000
    }
    
    public func consumeFuel(speed: Double, distance: Double) {
        if speed >= 60 {
            self._fuelRemaining! -= (distance / self._mpgHwy!)
        } else if speed < 60 {
            self._fuelRemaining! -= (distance / self._mpgCity!)
        }
    }
    
}
