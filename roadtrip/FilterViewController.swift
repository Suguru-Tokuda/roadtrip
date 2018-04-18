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
    private var sortedKeys: [FilterKeywordWithImage] {
        return searchLocations.sorted(by: {$0.key < $1.key})
    }
    
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
        return searchLocations.count
//        return filterTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "typeCell", for: indexPath)
        let key = sortedKeys[indexPath.row]
        let type = key.name
        cell.textLabel?.text = type
        cell.imageView?.image = key.icon
        cell.accessoryType = selectedTypes.contains(key.key) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = sortedKeys[indexPath.row]
        if selectedTypes.contains(key.key) {
            selectedTypes = selectedTypes.filter({$0 != key.key})
        } else {
            selectedTypes.append(key.key)
        }
        
        tableView.reloadData()
    }
}
