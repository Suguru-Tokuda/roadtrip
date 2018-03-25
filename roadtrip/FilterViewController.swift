//
//  FilterViewController.swift
//  roadtrip
//
//  Created by sanket bhat on 3/23/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

protocol FilterTableViewControllerDelegate: class {
    func typesController(_ controller: FilterTableViewController, didSelectTypes types: [String])
}
class FilterTableViewController: UITableViewController {
    private var sortedKeys: [String] {
        return filterTypes.keys.sorted()
    }
    private let filterTypes = ["food": "Food", "gas_station": "Gas Station", "petrol": "Petrol"]
    var selectedTypes = [String]()
    var delegate: FilterTableViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func FilterDone(_ sender: UIBarButtonItem) {
        delegate?.typesController(self, didSelectTypes: selectedTypes)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterTypes.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "typeCell", for: indexPath)
        let key = sortedKeys[indexPath.row]
        let type = filterTypes[key]
        cell.textLabel?.text = type
        cell.imageView?.image = UIImage(named: key)
        cell.accessoryType = selectedTypes.contains(key) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = sortedKeys[indexPath.row]
        if selectedTypes.contains(key) {
            selectedTypes = selectedTypes.filter({$0 != key})
        } else {
            selectedTypes.append(key)
        }
        
        tableView.reloadData()
    }
}
