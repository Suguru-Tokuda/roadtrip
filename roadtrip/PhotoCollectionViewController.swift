//
//  PhotoCollectionViewController.swift
//  roadtrip
//
//  Created by Suguru on 4/16/18.
//  Copyright © 2018 edu.ilstu.stokudasabhat. All rights reserved.
//

import UIKit

class PhotoCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var photoReferences: [String]?
    var photos: [String: UIImage]?
    var photoRef: String?
    var name: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photos = [String: UIImage]()
        self.navigationItem.title = name!
    }
    
    private func getPhoto(photoReference: String, cell: PhotoCollectionViewCell) {
        URLSession.shared.dataTask(with: RoadtripAPI.googlePhotoURL(photoReference: photoReference)) {
            (data, response, error) -> Void in
            OperationQueue.main.addOperation {
                let image = UIImage(data: data!)
                self.photos![photoReference] = image
                cell.update(with: image)
            }
        }.resume()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(self.photoReferences!.count)
        return self.photoReferences!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = "photoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        self.getPhoto(photoReference: self.photoReferences![indexPath.row], cell: cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        photoRef = photoReferences![indexPath.row]
        performSegue(withIdentifier: "showPhoto", sender: self)        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
         let vc = segue.destination as! PhotoViewController
            vc.name = self.name!
            vc.photoToShow = photos![photoRef!]
        }
    }
    
}
