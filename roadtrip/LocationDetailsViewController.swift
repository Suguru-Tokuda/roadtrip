//
//  LocationDetailsViewController.swift
//  roadtrip
//
//  Created by Suguru on 4/16/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class LocationDetailsViewController: UIViewController {

    var placeDetail:PlaceDetail?
    var photoReferences: [String]?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var urlTextView: UITextView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var hoursTextView: UITextView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var reviewsTextView: UITextView!
    var showPhotosBtn: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = placeDetail!.result!.name
        phoneTextView.text = placeDetail!.result!.internationalphonenumber
        phoneTextView.dataDetectorTypes = .phoneNumber
        phoneTextView.isEditable = false
        urlTextView.text = placeDetail!.result!.url!
        urlTextView.dataDetectorTypes = .link
        urlTextView.isEditable = false
        addressLabel.text = "Address: \(String(describing: placeDetail!.result!.formattedaddress!))"
        var hoursStr = "Hours:"
        for openHours in placeDetail!.result!.openinghours!.weekdaytext! {
            hoursStr += "\n\(openHours)"
        }
        hoursTextView.text = hoursStr
        hoursTextView.isEditable = false
        let ratingsStackView = UIStackView()
        ratingsStackView.axis = .horizontal
        
        for _ in 0..<Int(placeDetail!.result!.rating!) {
            let imageView = UIImageView()
            let image = UIImage(named: "star")
            imageView.image = image
            imageView.tintColor = UIColor(red: 1, green: 0.7804, blue: 0, alpha: 1.0)
            ratingsStackView.addArrangedSubview(imageView)
        }
        ratingsStackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(ratingsStackView)
        ratingsStackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20).isActive = true
        ratingsStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        ratingsStackView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10).isActive = true
        
        if photoReferences!.count > 0 {
            showPhotosBtn = UIButton()
            showPhotosBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
            showPhotosBtn!.setTitle("See Pictures", for: .normal)
            showPhotosBtn!.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
            showPhotosBtn!.layer.cornerRadius = 5
            showPhotosBtn!.setTitleColor(.white, for: .normal)
            showPhotosBtn!.addTarget(self, action: #selector(showPhotosBtnTapped), for: .touchUpInside)
            showPhotosBtn!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(showPhotosBtn!)
            showPhotosBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
            showPhotosBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            showPhotosBtn!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
            showPhotosBtn!.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        }
        
        if let reviews = placeDetail?.result?.reviews {
            reviewsTextView.isEditable = false
            var reviewStr = String()
            for review in reviews {
                reviewStr += "Reviewed by : \(review.authorname!.description)\n"
                reviewStr += "Rating: \(review.rating!.description)\n"
                reviewStr += "Reviewed at: \(review.relativetimedescription!.description)\n"
                reviewStr += "Comment: \(review.text!.description)\n"
            }
            reviewsTextView.text = reviewStr
            reviewsTextView.translatesAutoresizingMaskIntoConstraints = false
            reviewsTextView.heightAnchor.constraint(equalToConstant: 300).isActive = false
            reviewsTextView.topAnchor.constraint(lessThanOrEqualTo: ratingsStackView.bottomAnchor, constant: 10).isActive = true
            reviewsTextView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20).isActive = true
            reviewsTextView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20).isActive = true
            if let button = showPhotosBtn {
                reviewsTextView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: 10).isActive = true
            } else {
                reviewsTextView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
            }
        }
    }
    
    @objc private func showPhotosBtnTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: "showPictures", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPictures" {
            let vc = segue.destination as! PhotoCollectionViewController
            vc.photoReferences = photoReferences!
            vc.name = self.placeDetail!.result!.name
        }
    }

    

}
