//
//  CoreDataHandler.swift
//  roadtrip
//
//  Created by Suguru on 4/14/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//
import UIKit
import Foundation
import CoreData

public class CoreDataHandler: NSObject {
    
    private static func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate!.persistentContainer.viewContext
    }
    
    public static func saveCar(car: Car) -> Bool {
        let context = getContext()
        let entity = NSEntityDescription.entity(forEntityName: "CarData", in: context)
        let managedObject = NSManagedObject(entity: entity!, insertInto: context)
        
        managedObject.setValue(car.id, forKey: "id")
        managedObject.setValue(car.make, forKey: "make")
        managedObject.setValue(car.model, forKey: "model")
        managedObject.setValue(car.trim, forKey: "trim")
        managedObject.setValue(car.year, forKey: "year")
        managedObject.setValue(car.fuelCapacity, forKey: "fuelCapacity")
        managedObject.setValue(car.fuelRemainingInPercent, forKey: "fuelRemainingInPercent")
        managedObject.setValue(car.gasType, forKey: "gasType")
        managedObject.setValue(car.mpgHwy, forKey: "mpgHwy")
        managedObject.setValue(car.mpgCity, forKey: "mpgCity")
        
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    public static func fetchCar() -> Car? {
        let context = getContext()
        var cars: [CarData]? = nil
        var retVal: Car?
        do {
            cars = try context.fetch(CarData.fetchRequest())
            for car in cars! {
                let make = car.make!
                let model = car.model!
                let trim = car.trim!
                let year = car.year!
                let fuelCapacity = car.fuelCapacity
                let gasType = car.gasType!
                let mpgHwy = car.mpgHwy
                let mpgCity = car.mpgCity
                retVal = Car(make: make, model: model, trim: trim, year: year, fuelCapacity: fuelCapacity, gasType: gasType, mpgHwy: mpgHwy, mpgCity: mpgCity)
            }
            return retVal
        } catch {
            return nil
        }
    }
    
    public static func deleteCar(car: Car) -> Bool {
        let context = getContext()
        var resultSet: [CarData]?
        let fetchRequest: NSFetchRequest<CarData> = CarData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", car.id)
        do {
            resultSet = try context.fetch(fetchRequest)
            context.delete(resultSet![0])
            try context.save()
        } catch {
            return false
        }
        return false
    }
    
    public static func updateCar(car: Car) -> Bool {
        let context = getContext()
        var resultSet: [CarData]?
        let fetchRequest: NSFetchRequest<CarData> = CarData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", car.id)
        do {
            resultSet = try context.fetch(fetchRequest)
            let tempCar: CarData = resultSet![0]
            tempCar.make = car.make
            tempCar.model = car.model
            tempCar.trim = car.trim
            tempCar.year = car.year
            tempCar.fuelCapacity = car.fuelCapacity
            tempCar.fuelRemainingInPercent = car.fuelRemainingInPercent
            tempCar.mpgHwy = car.mpgHwy
            tempCar.mpgCity = car.mpgCity
            try context.save()
            return true
        } catch {
            return false
        }
    }
    
    public static func cleanDelete() -> Bool {
        let context = getContext()
        let delete = NSBatchDeleteRequest(fetchRequest: CarData.fetchRequest())
        do {
            try context.execute(delete)
            return true
        } catch {
            return false
        }
    }
    
}
