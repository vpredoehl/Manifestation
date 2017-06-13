//
//  ViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 4/30/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let maxNumPositions = 3

class RolloverViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // MARK: Properties -
    @IBOutlet weak var chiImageView: UIImageView!
    @IBOutlet weak var rolloverImageView: UIImageView!
    @IBOutlet weak var trashItem: UIBarButtonItem!

    var pref: Preference!
        
    override func viewDidLoad() {
        let dd = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let f = dd.appendingPathComponent(positionFile)
        let p = NSKeyedUnarchiver.unarchiveObject(withFile: f.path) as? Preference
        
        pref = p ?? Preference(transfer: nil, imageIndex: nil, trendText: [ "" ], targetText: [ "" ], segments: nil, numPositions: 1)
        
        if let d = pref?.chiTransferImage {
            rolloverImageView.image = UIImage(data: d)
        }
        super.viewDidLoad()
    }

    // MARK: - Tool Bar -
    @IBAction func trash(_ sender: Any) {
        let ac = UIAlertController()
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let transfer = UIAlertAction(title: "Delete Transfer Image", style: .destructive)
        {
            (_) in
            let f = Preference.DocDir.appendingPathComponent(chiImageFile)

            self.pref.chiTransferImage = nil
            self.chiImageView.image = nil
            NSKeyedArchiver.archiveRootObject(self.pref.chiTransferImage as Any, toFile: f.path)
        }
        let position = UIAlertAction(title: "Delete Rollver Images", style: .destructive)
        {
            (_) in
            let f = Preference.DocDir.appendingPathComponent(positionFile)
            
            self.pref.removeAll()
            NSKeyedArchiver.archiveRootObject(self.pref, toFile: f.path)
        }
        
        if let vc = ac.popoverPresentationController {
            vc.barButtonItem = trashItem
        }
        
        ac.addAction(cancel)
        ac.addAction(transfer)
        ac.addAction(position)
        present(ac, animated: true)
    }
    @IBAction func playRollover(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        rolloverImageView.image = img
        pref.chiTransferImage = UIImagePNGRepresentation(img)
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! PositionTableViewController
        
        dest.pref = pref.copy() as! Preference
    }
}

