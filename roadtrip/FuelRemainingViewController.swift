//
//  FuelRemainingViewController.swift
//  roadtrip
//
//  Created by Suguru on 3/23/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class FuelRemainingViewController: UIViewController {
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    var myCar: Car?
    
    @IBOutlet weak var fuelRemainingSlider: UISlider!
    @IBOutlet weak var fuelLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCar = appDelegate?.myCar
        fuelRemainingSlider.value = Float(myCar!.fuelRemainingInPercent)
        percentageLabel.text = "\(fuelRemainingSlider.value.description)%"
        fuelLabel.text = "\(String(describing: myCar!.getFuelRemaining())) / \(String(describing: myCar!.fuelCapacity)) gallons"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func fuelRemainingSliderChanged(_ sender: Any) {
        myCar?.fuelRemainingInPercent = Double(fuelRemainingSlider.value)
        let percentage = round(1000 * fuelRemainingSlider.value)/1000
        percentageLabel.text = "\(percentage.description)%"
        fuelLabel.text = "\(String(describing: myCar!.getFuelRemaining())) / \(String(describing: myCar!.fuelCapacity)) gallons"
    }
    
    @IBAction func ctnBtnClicked(_ sender: Any) {
        appDelegate?.myCar?.fuelRemainingInPercent = Double(fuelRemainingSlider.value)
    }
    
    

}
