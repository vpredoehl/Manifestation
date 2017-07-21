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
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var trashItem: UIBarButtonItem!
    @IBOutlet weak var tb: UIToolbar!

    @IBOutlet var constraintsForFullChiView: [NSLayoutConstraint]!
    @IBOutlet var constraintsForReducedChiView: [NSLayoutConstraint]!
    
    let animLG = UILayoutGuide()
    var pref: Preference!
    var isAnimating = false
    var animationVC: AnimationViewController!
    
    var chiImageView: UIImageView   {   get {   return animationVC.chiImageView }   }
    
    override func viewDidLoad() {
        let dd = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let f = dd.appendingPathComponent(positionFile)
        let p = NSKeyedUnarchiver.unarchiveObject(withFile: f.path) as? Preference
        
        view.addLayoutGuide(animLG)
        let topG = animLG.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 0)
        let bottomG = animLG.bottomAnchor.constraint(equalTo: tb.topAnchor, constant: 0)
        let leftG = animLG.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8)
        let rightG = animLG.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8)
        NSLayoutConstraint.activate([topG, bottomG, leftG, rightG])
        
        let width = animationView.widthAnchor.constraint(equalTo: animLG.widthAnchor, constant: -16)
        let height = animationView.heightAnchor.constraint(equalTo: animLG.heightAnchor, constant: -16)
        constraintsForFullChiView.append(contentsOf: [width, height])
        
        pref = p ?? Preference(transfer: nil, imageIndex: nil, trendText: [ "" ], targetText: [ "" ], segments: nil, numPositions: 1)
        
        if let d = pref?.chiTransferImage {
            chiImageView.image = UIImage(data: d)
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
    @IBAction func playRollover(_ playBtn: UIBarButtonItem) {
        let willBeAnimating = !isAnimating
        let pt1 = CGPoint(x: 0.1, y: 1.0)
        let pt2 = CGPoint(x: 0.5, y: 1.0)
        

        let anim = UIViewPropertyAnimator(duration: 2, controlPoint1: pt1, controlPoint2: pt2) {
//            self.chiImageView.frame = willBeAnimating ? self.view.frame.insetBy(dx: 16, dy: 16) :  self.frameForChiView
            if willBeAnimating {
                NSLayoutConstraint.deactivate(self.constraintsForReducedChiView)
                NSLayoutConstraint.activate(self.constraintsForFullChiView)
            } else {
                NSLayoutConstraint.deactivate(self.constraintsForFullChiView)
                NSLayoutConstraint.activate(self.constraintsForReducedChiView)
            }
            self.view.layoutIfNeeded()
        }

        tb.items![2] = UIBarButtonItem(barButtonSystemItem: isAnimating ? UIBarButtonSystemItem.play : UIBarButtonSystemItem.pause, target: self, action: #selector(RolloverViewController.playRollover(_:)))
        anim.startAnimation()
        isAnimating = !isAnimating
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        chiImageView.image = img
        pref.chiTransferImage = UIImagePNGRepresentation(img)
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case  "PositionSegue":
            let dest = segue.destination as! PositionTableViewController
            
            dest.pref = pref.copy() as! Preference
        case "AnimationSegue":
            animationVC = segue.destination as! AnimationViewController
        default: break
        }
    }
}

