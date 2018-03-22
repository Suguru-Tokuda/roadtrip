//
//  CarInfoSettingViewController.swift
//  roadtrip
//
//  Created by Suguru on 3/13/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class CarInfoSettingViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var yearPicker: UIPickerView! = UIPickerView()
    var makePicker: UIPickerView! = UIPickerView()
    var modelPicker: UIPickerView! = UIPickerView()
    var trimPicker: UIPickerView! = UIPickerView()
    var gasTypePicker: UIPickerView! = UIPickerView()
    
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var makeTextField: UITextField!
    @IBOutlet weak var modelTextField: UITextField!
    @IBOutlet weak var trimTextField: UITextField!
    @IBOutlet weak var gasTypeTextField: UITextField!
    @IBOutlet weak var mileageTextField: UITextField!
    
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
        setUpDoneBtn()
        yearPicker.dataSource = self
        yearPicker.delegate = self
        makePicker.dataSource = self
        makePicker.delegate = self
        modelPicker.dataSource = self
        modelPicker.delegate = self
        trimPicker.dataSource = self
        trimPicker.delegate = self
        gasTypePicker.dataSource = self
        gasTypePicker.delegate = self
        
        yearTextField.inputView = yearPicker
        makeTextField.inputView = makePicker
        modelTextField.inputView = modelPicker
        trimTextField.inputView = trimPicker
        gasTypeTextField.inputView = gasTypePicker
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.title = "Your Car Info"
        self.years = self.appDelegate!.years
        self.selectedGasType = gasTypes[0]
        gasTypeTextField.text = self.selectedGasType
        self.carQueryDataStore.getYears { (yearsResult) in
            switch yearsResult {
            case let .success(years):
                self.years =  years
                self.years?.sort(by: >)
                self.selectedYear = self.years![0]
                self.yearTextField.text = self.selectedYear!.description
                self.carQueryDataStore.getMakes(year: self.selectedYear!, completion: { (makesResult) in
                    switch makesResult {
                    case let .success(makes):
                        if makes.count > 0 {
                            self.makes = makes
                            self.selectedMake = self.makes![0]
                            self.makeTextField.text = self.selectedMake!.makeDisplay
                            self.carQueryDataStore.getModels(make: self.makes![0].makeDisplay.lowercased(), year: self.selectedYear!, completion: { (modelsResult) in
                                switch modelsResult {
                                case let .success(models):
                                    self.models = models
                                    self.selectedModel = self.models![0]
                                    self.modelTextField.text = self.selectedModel!.modelName
                                    if models.count > 0 {
                                        let modelName = self.models![0].modelName.lowercased()
                                        self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                                            switch trimsResult {
                                            case let .success(trims):
                                                self.trims = trims
                                                if trims.count > 0 {
                                                    self.selectedTrim = self.trims![0]
                                                    self.trimTextField.text = self.selectedTrim!.modelTrim
                                                    self.trimPicker.reloadAllComponents()
                                                } else {
                                                    self.selectedTrim = nil
                                                    self.trimTextField.text = ""
                                                }
                                            case let .failure(error):
                                                print(error)
                                            }
                                        })
                                        self.modelPicker.reloadAllComponents()
                                    } else {
                                        self.selectedModel = nil
                                        self.modelTextField.text = ""
                                    }
                                case let .failure(error):
                                    print(error)
                                }
                            })
                        } else {
                            self.selectedMake = nil
                            self.makeTextField.text = ""
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
            yearTextField.text = selectedYear!.description
            self.carQueryDataStore.getMakes(year: selectedYear!, completion: { (makesResult) in
                switch makesResult {
                case let .success(makes):
                    if makes.count > 0 {
                        self.makes = makes
                        self.selectedMake = self.makes![0]
                        self.makeTextField.text = self.selectedMake!.makeDisplay
                        self.carQueryDataStore.getModels(make: self.makes![0].makeDisplay.lowercased(), year: self.selectedYear!, completion: { (modelsResult) in
                            switch modelsResult {
                            case let .success(models):
                                self.models = models
                                self.selectedModel = self.models![0]
                                self.modelTextField.text = self.selectedModel!.modelName
                                if models.count > 0 {
                                    let modelName = self.models![0].modelName.lowercased()
                                    self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                                        switch trimsResult {
                                        case let .success(trims):
                                            self.trims = trims
                                            if trims.count > 0 {
                                                self.selectedTrim = self.trims![0]
                                                self.trimTextField.text = self.selectedTrim!.modelTrim
                                                self.trimPicker.reloadAllComponents()
                                            } else {
                                                self.selectedTrim = nil
                                                self.trimTextField.text = ""
                                            }
                                        case let .failure(error):
                                            print(error)
                                        }
                                    })
                                    self.modelPicker.reloadAllComponents()
                                } else {
                                    self.selectedModel = nil
                                    self.modelTextField.text = ""
                                }
                            case let .failure(error):
                                print(error)
                            }
                        })
                    } else {
                        self.selectedMake = nil
                        self.makeTextField.text = ""
                    }
                    self.makePicker.reloadAllComponents()
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == makePicker {
            selectedMake = makes![row]
            makeTextField.text = selectedMake!.makeDisplay
            self.carQueryDataStore.getModels(make: selectedMake!.makeDisplay.lowercased(), year: selectedYear!, completion: { (modelsResult) in
                switch modelsResult {
                case let .success(models):
                    self.models = models
                    if models.count > 0 {
                        self.selectedModel = self.models![0]
                        self.modelTextField.text = self.selectedModel!.modelName
                        let modelName = self.models![0].modelName.lowercased()
                        self.carQueryDataStore.getTrims(model: modelName, year: self.selectedYear!, completion: { (trimsResult) in
                            switch trimsResult {
                            case let .success(trims):
                                self.trims = trims
                                if trims.count > 0 {
                                    self.selectedTrim = self.trims![0]
                                    self.trimTextField.text = self.selectedTrim!.modelTrim
                                    self.trimPicker.reloadAllComponents()
                                } else {
                                    self.selectedTrim = nil
                                    self.trimTextField.text = ""
                                }
                            case let .failure(error):
                                print(error)
                            }
                        })
                        self.modelPicker.reloadAllComponents()
                    } else {
                        self.selectedModel = nil
                        self.modelTextField.text = ""
                    }
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == modelPicker {
            selectedModel = models![row]
            modelTextField.text = selectedModel!.modelName
            self.carQueryDataStore.getTrims(model: selectedModel!.modelName.lowercased(), year: selectedYear!, completion: { (trimsResult) in
                switch trimsResult {
                case let .success(trims):
                    if trims.count > 0 {
                        self.trims = trims
                        self.selectedTrim = self.trims![0]
                        self.trimTextField.text = self.selectedTrim!.modelTrim
                        self.trimPicker.reloadAllComponents()
                    } else {
                        self.selectedTrim = nil
                        self.trimTextField.text = ""
                    }
                case let .failure(error):
                    print(error)
                }
            })
        } else if pickerView == trimPicker {
            selectedTrim = trims![row]
            trimTextField.text = selectedTrim!.modelTrim
        } else if pickerView == gasTypePicker {
            selectedGasType = gasTypes[row]
            gasTypeTextField.text = selectedGasType!
        }
    }
    
    private func setUpDoneBtn() {
        let toolBar = UIToolbar()
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClicked))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolBar.items = [flexibleSpace, doneBtn]
        toolBar.sizeToFit()
    }
    
    @objc func doneClicked() {
        view.endEditing(false)
    }
    
    @IBAction func displayTapped(_ sender: Any) {
        self.view.endEditing(false)
    }
    
    @IBAction func setCarInfoBtnClicked(_ sender: Any) {
        guard selectedMake != nil && selectedModel != nil && selectedTrim != nil && mileageTextField.text != "" else {
            let carInfoConfAlert = UIAlertController(title: "Complete the Form", message: "Required to start your trip", preferredStyle: .alert)
            carInfoConfAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(carInfoConfAlert, animated: true, completion: nil)
            return
        }
        let year = selectedYear?.description
        let mileage = Double(mileageTextField.text!)
        tempCar = Car(make: selectedMake!.makeDisplay, model: selectedModel!.modelName, trim: selectedTrim!.modelTrim, year: year!, mileage: mileage!, gasType: selectedGasType!, mpgHwy: selectedTrim!.mpgHwy, mpgCity: selectedTrim!.mpgCity)
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
