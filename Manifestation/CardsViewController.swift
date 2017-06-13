//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class CardsViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties -
    @IBOutlet weak var cameraItem: UIBarButtonItem!

    var returnImageIdx, row: Int!
    var userImage: UIImage?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let insets = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        
        collectionView?.scrollIndicatorInsets = insets
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.title = "Cards"
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = UIImage(named: "AoD/\(indexPath.row + 1)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        
        cell.imageView.image = img
        cell.imgIdx = indexPath.row
        return cell
        
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AoDCount
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? CardCollectionViewCell {
            returnImageIdx = cell.imgIdx
        }
    }
    
    // MARK: - Image Picker Controller -
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        let ac = UIAlertController()
        let choosePhoto =
        {
            (_: UIAlertAction) in
            let ip = UIImagePickerController()
            
            ip.delegate = self
            ip.sourceType = .photoLibrary
            self.present(ip, animated: true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default, handler: choosePhoto)
        let camera = UIAlertAction(title: "Camera", style: .default)
        {
            (_) in
            let ip = UIImagePickerController()
            
            ip.delegate = self
            ip.sourceType = .camera
            self.present(ip, animated: true)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(cancel)
            ac.addAction(camera)
            ac.addAction(photoLibrary)
            
            if let vc = ac.popoverPresentationController {
                vc.barButtonItem = cameraItem
            }
            
            present(ac, animated: true)
        }
        else {
            choosePhoto(UIAlertAction())
        }
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        userImage = info[UIImagePickerControllerOriginalImage] as! UIImage?
        returnImageIdx = -row - 1
        performSegue(withIdentifier: "UnwindWithSelectedImage", sender: self)
    }
}
