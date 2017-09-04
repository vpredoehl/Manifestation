//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class HeaderView: UICollectionViewCell {
    @IBOutlet weak var headerText: UILabel!
}

class CardsViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: Properties -
    @IBOutlet weak var cameraItem: UIBarButtonItem!

    var pref: Preference!
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
    
    // MARK: - Collection View Data Source -

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = UIImage(named: "AoD/\(indexPath.row + 1)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        
        switch indexPath.section {
        case 0:
            let idx = Preference.userPhotoKeys![indexPath.item]
            cell.imageView.image = pref.image(forKey: idx)
            cell.imgIdx = idx
        case 1:
            cell.imageView.image = img
            cell.imgIdx = indexPath.item
        default:
            break
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let v = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "cardHeader", for: indexPath) as! HeaderView
        
        switch indexPath.section {
        case 0:
            v.headerText.text = "User Photos"
        case 1:
            v.headerText.text = "Alphabet of Desire"
        default: break
        }
        return v
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch section {
        case 0:
            let userKeys = Preference.userPhotoKeys
            if userKeys == nil || section == 0 && userKeys!.count == 0 {
                return .zero
            }
        default: break
        }
        return CGSize(width: 0, height: 50)
    }
    
    // MARK: - Collection View Delegate -
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            guard let userKeys = Preference.userPhotoKeys else { return 0 }
            return userKeys.count
        case 1:
            return AoDCount
        default:
            return 0
        }
    }
    
    
    // MARK: -
    
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
        let timestamp = Int(CFAbsoluteTimeGetCurrent())
        
        userImage = info[UIImagePickerControllerOriginalImage] as! UIImage?
        returnImageIdx = -timestamp
        performSegue(withIdentifier: "UnwindWithSelectedImage", sender: self)
    }
}
