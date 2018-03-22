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
    @IBOutlet weak var mileageTextField: UITextField!
    @IBOutlet weak var gasTypeTextField: UITextField!
    
    var tempCar: Car?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        yearTextField.isEnabled = false
        makeTextField.isEnabled = false
        modelTextField.isEnabled = false
        trimTextField.isEnabled = false
        mpgHwyTextField.isEnabled = false
        mpgCityTextField.isEnabled = false
        mileageTextField.isEnabled = false
        gasTypeTextField.isEnabled = false
        
        yearTextField.text = tempCar!.year
        makeTextField.text = tempCar!.make
        modelTextField.text = tempCar!.model
        trimTextField.text = tempCar!.trim
        mpgHwyTextField.text = tempCar!.mpgHwy.description
        mpgCityTextField.text = tempCar!.mpgCity.description
        mileageTextField.text = tempCar!.mileage.description
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
        
    }
    
    
    
}
