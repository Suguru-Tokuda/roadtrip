//
//  CarInfoConfirmationViewController.swift
//  roadtrip
//
//  Created by Suguru on 3/15/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class CarInfoConfirmationViewController: UIViewController {
    
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var makeTextField: UITextField!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var trimTextField: UITextField!
    @IBOutlet weak var mpgHwyTextField: UITextField!
    @IBOutlet weak var mpgCityTextField: UITextField!
    @IBOutlet weak var fuelCapacityTextField: UITextField!
    @IBOutlet weak var gasTypeTextField: UITextField!
    
    @IBOutlet weak var setAgainBtn: UIButton!
    @IBOutlet weak var confBtn: UIButton!
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    var tempCar: Car?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAgainBtn.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        setAgainBtn.layer.cornerRadius = 5
        setAgainBtn.setTitleColor(UIColor.white, for: .normal)
        confBtn.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        confBtn.layer.cornerRadius = 5
        confBtn.setTitleColor(UIColor.white, for: .normal)
        
        tempCar = appDelegate?.myCar
        yearTextField.isEnabled = false
        makeTextField.isEnabled = false
        modelTextField.isEnabled = false
        trimTextField.isEnabled = false
        mpgHwyTextField.isEnabled = false
        mpgCityTextField.isEnabled = false
        fuelCapacityTextField.isEnabled = false
        gasTypeTextField.isEnabled = false
        
        yearTextField.text = tempCar!.year
        makeTextField.text = tempCar!.make
        modelTextField.text = tempCar!.model
        trimTextField.text = tempCar!.trim
        mpgHwyTextField.text = tempCar!.mpgHwy.description
        mpgCityTextField.text = tempCar!.mpgCity.description
        fuelCapacityTextField.text = String(tempCar!.fuelCapacity)
        gasTypeTextField.text = tempCar!.gasType
        
        self.navigationItem.setHidesBackButton(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func backBtnClicked(_ sender: Any) {
        performSegue(withIdentifier: "backToCarInfoInput", sender: self)
        
    }
    
    @IBAction func confirmBtnClicked(_ sender: Any) {
        if appDelegate!.hasCarInfo == false {
            // create a new care data
            CoreDataHandler.saveCar(car: tempCar!)
        } else {
            // update
            CoreDataHandler.updateCar(car: tempCar!)
        }
        performSegue(withIdentifier: "carInfoConfirm", sender: self)
    }
    
    
    
}
