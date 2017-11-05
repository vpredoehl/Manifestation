//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class HeaderView: UICollectionReusableView {
    @IBOutlet weak var headerText: UILabel!
    @IBOutlet weak var sizeSlider: UISlider!
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
        if popoverPresentationController != nil {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.title = "Cards"
    }
    
    // MARK: - Collection View Data Source -

    @IBAction func sliderMoved(_ sender: UISlider) {
        let l = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        let v = Int(sender.value)
        
        l.itemSize = CGSize(width: v, height: v)
        l.invalidateLayout()
        print("Slider: \(sender.value)")
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = UIImage(named: "AoD/\(indexPath.row + 1)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        
        switch indexPath.section {
        case 0:
            let idx = RolloverPresets.userPhotoKeys![indexPath.item]
            cell.imageView.image = pref.image(forKey: idx)
            cell.imgIdx = idx
        case 1:
            cell.imageView.image = img
            cell.imgIdx = indexPath.item
        default:
            return CardCollectionViewCell()
        }
        cell.imageView.contentMode = .scaleAspectFit
        cell.tag = indexPath.section

        if cell.gestureRecognizers == nil {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(CardsViewController.longPress(_:)))
            cell.addGestureRecognizer(longPress)
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
            let userKeys = RolloverPresets.userPhotoKeys
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
            guard let userKeys = RolloverPresets.userPhotoKeys else { return 0 }
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
    enum UserPhotoSelectionActionType {
        case none
        case camera
        case photoLibrary
    }
    var actionType: UserPhotoSelectionActionType = .none
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        let ac = UIAlertController()
        let choosePhoto =
        {
            (_: UIAlertAction) in
            let ip = UIImagePickerController()
            
            ip.delegate = self
            ip.modalPresentationStyle = .overCurrentContext
            ip.sourceType = .photoLibrary
            self.actionType = .photoLibrary
            self.present(ip, animated: true)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default, handler: choosePhoto)
        let camera = UIAlertAction(title: "Camera", style: .default)
        {
            (_) in
            let ip = UIImagePickerController()
            
            ip.delegate = self
            ip.modalPresentationStyle = .overCurrentContext
            ip.sourceType = .camera
            self.actionType = .camera
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
        switch actionType {
        case .none:
            break
        case .camera:   // camera photos are
            returnImageIdx = returnImageIdx -  returnImageIdx & 1
        case .photoLibrary:
            returnImageIdx = returnImageIdx | 1
        }
        performSegue(withIdentifier: "UnwindWithSelectedImage", sender: self)
    }
    
    // MARK: - Navigation
    lazy var expandTransition = ExpandDel()
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
        let previewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShowImage") as! PreviewVC
        let cell = sender.view as! CardCollectionViewCell
        let imgV = cell.imageView!
        let section = cell.tag
        
        previewVC.loadViewIfNeeded()
        previewVC.modalPresentationStyle = .custom
        previewVC.transitioningDelegate = expandTransition
        switch section {
        case 0:
            previewVC.imageView.image = pref.image(forKey: cell.imgIdx)
        case 1:
            let img = UIImage(named: "AoD/\(cell.imgIdx + 1)")
            previewVC.imageView.image = img
        default:
            return
        }
        
        imgV.isHidden = true
        expandTransition.previewFrame = imgV.superview!.convert(imgV.frame, to: nil)
        expandTransition.previewCompletion = {
            cell.imageView.isHidden = false
        }
        present(previewVC, animated: true)
    }
}

