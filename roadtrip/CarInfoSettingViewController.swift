//
//  CarInfoSettingViewController.swift
//  roadtrip
//
//  Created by Suguru on 3/13/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class CarInfoSettingViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var yearPicker: UIPickerView!
    @IBOutlet weak var makePicker: UIPickerView!
    @IBOutlet weak var modelPicker: UIPickerView!
    @IBOutlet weak var trimPicker: UIPickerView!
    @IBOutlet weak var gasTypePicker: UIPickerView!
    @IBOutlet weak var millageTextField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    let carQueryDataStore = CarQueryDataStore()
    var years: [Int]?
    var makes: [Make]?
    var models: [Model]?
    var trims: [Trim]?
    var gasTypes: [String] = ["Unleased", "Plus", "Premium"]
    var selectedYear: Int?
    var selectedMake: Make?
    var selectedModel: Model?
    var selectedTrim: Trim?
    var selectedGasType: String?
    var tempCar: Car!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.title = "Your Car Info"
        self.years = self.appDelegate!.years
        self.selectedGasType = gasTypes[0]
        self.carQueryDataStore.getYears { (yearsResult) in
            switch yearsResult {
            case let .success(years):
                self.years =  years
                self.years?.sort(by: >)
                self.selectedYear = self.years![0]
                self.carQueryDataStore.getMakes(year: self.selectedYear!, completion: { (makesResult) in
                    switch makesResult {
                    case let .success(makes):
                        if makes.count > 0 {
                            self.makes = makes
                            self.selectedMake = self.makes![0]
                            self.carQueryDataStore.getModels(make: self.makes![0].makeDisplay.lowercased(), year: self.selectedYear!, completion: { (modelsResult) in
                                switch modelsResult {
                                case let .success(models):
                                    self.models = models
                                    self.selectedModel = self.models![0]
                                    if models.count > 0 {
                                        let modelName = self.models![0].modelName.lowercased()
                                        self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                                            switch trimsResult {
                                            case let .success(trims):
                                                self.trims = trims
                                                self.selectedTrim = self.trims![0]
                                                self.trimPicker.reloadAllComponents()
                                            case let .failure(error):
                                                print(error)
                                            }
                                        })
                                        self.modelPicker.reloadAllComponents()
                                    } else {
                                        self.selectedModel = nil
                                    }
                                case let .failure(error):
                                    print(error)
                                }
                            })
                        } else {
                            self.selectedMake = nil
                        }
                        self.makePicker.reloadAllComponents()
                    case let .failure(error):
                        print(error)
                    }
                })
                self.yearPicker.reloadAllComponents()
            case let .failure(error):
                print(error)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var returnStr: String?
        if pickerView == yearPicker {
            if let years = self.years {
                returnStr = String(years[row])
            } else {
                returnStr = ""
            }
        } else if pickerView == makePicker {
            if let makesConstant = makes {
                returnStr = makesConstant[row].makeDisplay
            } else {
                returnStr = ""
            }
        } else if pickerView == modelPicker {
            if let modelsConstant = models {
                returnStr = modelsConstant[row].modelName
            } else {
                returnStr = ""
            }
        } else if pickerView == trimPicker {
            if let trimsConstant = trims {
                returnStr = trimsConstant[row].modelTrim
            } else {
                returnStr = ""
            }
        } else if pickerView == gasTypePicker {
            returnStr = gasTypes[row]
        }
        return returnStr!
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var countRows: Int?
        if pickerView == yearPicker {
            if let years = self.years {
                countRows = years.count
            } else {
                countRows = 0
            }
        } else if pickerView == makePicker {
            if let makesConstant = makes {
                countRows = makesConstant.count
            } else {
                countRows = 0
            }
        } else if pickerView == modelPicker {
            if let modelsConstant = models {
                countRows = modelsConstant.count
            } else {
                countRows = 0
            }
        } else if pickerView == trimPicker {
            if let trimsConstant = trims {
                countRows = trimsConstant.count
            } else {
                countRows = 0
            }
        } else if pickerView == gasTypePicker {
            countRows = gasTypes.count
        }
        return countRows!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == yearPicker {
            selectedYear = years![row]
            self.carQueryDataStore.getMakes(year: selectedYear!, completion: { (makesResult) in
                switch makesResult {
                case let .success(makes):
                    if makes.count > 0 {
                        self.makes = makes
                        self.selectedMake = self.makes![0]
                        self.carQueryDataStore.getModels(make: self.makes![0].makeDisplay.lowercased(), year: self.selectedYear!, completion: { (modelsResult) in
                            switch modelsResult {
                            case let .success(models):
                                self.models = models
                                self.selectedModel = self.models![0]
                                if models.count > 0 {
                                    let modelName = self.models![0].modelName.lowercased()
                                    self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                                        switch trimsResult {
                                        case let .success(trims):
                                            self.trims = trims
                                            self.trimPicker.reloadAllComponents()
                                        case let .failure(error):
                                            print(error)
                                        }
                                    })
                                    self.modelPicker.reloadAllComponents()
                                } else {
                                    self.selectedModel = nil
                                }
                            case let .failure(error):
                                print(error)
                            }
                        })
                    } else {
                        self.selectedMake = nil
                    }
                    self.makePicker.reloadAllComponents()
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == makePicker {
            selectedMake = makes![row]
            self.carQueryDataStore.getModels(make: selectedMake!.makeDisplay.lowercased(), year: selectedYear!, completion: { (modelsResult) in
                switch modelsResult {
                case let .success(models):
                    self.models = models
                    self.selectedModel = self.models![0]
                    if models.count > 0 {
                        let modelName = self.models![0].modelName.lowercased()
                        self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                            switch trimsResult {
                            case let .success(trims):
                                self.trims = trims
                                self.trimPicker.reloadAllComponents()
                            case let .failure(error):
                                print(error)
                            }
                        })
                        self.modelPicker.reloadAllComponents()
                    } else {
                        self.selectedModel = nil
                    }
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == modelPicker {
            selectedModel = models![row]
            self.carQueryDataStore.getTrims(model: selectedModel!.modelName.lowercased(), year: selectedYear!, completion: { (trimsResult) in
                switch trimsResult {
                case let .success(trims):
                    self.trims = trims
                    self.trimPicker.reloadAllComponents()
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == trimPicker {
            selectedTrim = trims![row]
        } else if pickerView == gasTypePicker {
            selectedGasType = gasTypes[row]
        }
    }
    
    @IBAction func displayTapped(_ sender: Any) {
        self.view.endEditing(false)
    }
    
    @IBAction func setCarInfoBtnClicked(_ sender: Any) {
        guard selectedMake != nil && selectedModel != nil && selectedTrim != nil else {
            let carInfoConfAlert = UIAlertController(title: "Complete the Form", message: "Required to start your trip", preferredStyle: .alert)
            carInfoConfAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(carInfoConfAlert, animated: true, completion: nil)
            return
        }
        let year = selectedYear?.description
        let millage = Double(millageTextField.text!)
        tempCar = Car(make: selectedMake!.makeDisplay, model: selectedModel!.modelName, trim: selectedTrim!.modelTrim, year: year!, millage: millage!, gasType: selectedGasType!, mpgHwy: selectedTrim!.mpgHwy, mpgCity: selectedTrim!.mpgCity)
        performSegue(withIdentifier: "showCarSummary", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCarSummary" {
            if let carInfoConfVC = segue.destination as? CarInfoConfirmationViewController {
                carInfoConfVC.tempCar = self.tempCar
            }
        }
    }
    
}
