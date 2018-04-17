//
//  PhotoViewController.swift
//  roadtrip
//
//  Created by Suguru on 4/16/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
    
    var photoToShow: UIImage?
    var name: String?
    
    @IBOutlet weak var photo: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = name!
        photo.image = photoToShow!
    }

}
