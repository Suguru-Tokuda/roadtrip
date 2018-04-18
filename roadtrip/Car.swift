import Foundation
import UIKit
import CoreData

public class Car {
    
    private var _id: Int?
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
    private var _speeds: [Double]?
    
    // MARK: Initializer
    public init(make: String, model: String, trim: String, year: String, fuelCapacity: Double, gasType: String, mpgHwy: Double, mpgCity: Double) {
        self._id = 1
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
        self._speeds = [Double]()
    }
    
    // MARK: Getters & Setters
    public var id: Int {
        get {
            return self._id!
        }
    }
    
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
        var efficiency = 1.0
        if speed > 55 && speed <= 60 {
            efficiency = 0.97
        } else if speed > 60 && speed <= 65 {
            efficiency = 0.92
        } else if speed > 65 && speed <= 70 {
                efficiency = 0.83
        } else if speed > 70 && speed <= 75 {
            efficiency = 0.77
        } else if speed > 80 {
            efficiency = 0.72
        }
        if speed >= 60 {
            self._fuelRemaining! -= (distance / self._mpgHwy! / efficiency)
        } else if speed < 60 {
            self._fuelRemaining! -= (distance / self._mpgCity! / efficiency)
        }
        self._fuelRemainingInPercent = self._fuelRemaining! / self._fuelCapacity! * 100
    }
    
    public func appendSpeed(speed: Double) {
        if speed > 0 && !speed.isNaN {
            self._speeds!.append(speed)
        }
    }
    
    public func getSpeeds() -> Int {
        return self._speeds!.count
    }
    
    public func resetSpeeds() {
        self._speeds!.removeAll()
    }
    
    public func getAverageSpeed() -> Double {
        let count = self._speeds!.count
        var totalSpeeds = 0.0
        for speed in self._speeds! {
            totalSpeeds += speed
        }
        return totalSpeeds / Double(count)
    }
    
    public func getColorForFuelRemaining() -> UIColor {
        if _fuelRemainingInPercent! >= 75.0 {
            return UIColor(red: 0, green: 0.4824, blue: 1, alpha: 1.0)
        } else if _fuelRemainingInPercent! < 75.0 && _fuelRemainingInPercent! >= 50.0 {
            return UIColor(red: 0.1804, green: 1, blue: 0, alpha: 1.0)
        } else if _fuelRemainingInPercent! < 50.0 && _fuelRemainingInPercent! >= 25.0 {
            return UIColor(red: 1, green: 0.6, blue: 0, alpha: 1.0)
        } else {
            return UIColor(red: 1, green: 0, blue: 0, alpha: 1.0)
        }
    }
    
}
