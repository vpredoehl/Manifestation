//
//  ViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 4/30/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let maxNumPositions = 3

extension Preference
{
    var hasTransferSequence: Bool
    {
        get {
            if let ii = imageIndex {    // has non-nil image?
                for i in ii {
                    if i != nil    {   return true }
                }
            }
            return false
        }
    }
    var hasChiImage: Bool   {   get     {   return chiTransferImage != nil  }   }
    var canHiliteTrash: Bool {  get {   return hasChiImage || hasTransferSequence  }   }
    var canPlay: Bool   {   get     {   return hasChiImage && hasTransferSequence   }   }
}

class RolloverViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // MARK: Properties -
    @IBOutlet weak var animationView: UIView!
    @IBOutlet weak var trashItem: UIBarButtonItem!
    @IBOutlet weak var tb: UIToolbar!

    @IBOutlet var constraintsForFullChiView: [NSLayoutConstraint]!
    @IBOutlet var constraintsForReducedChiView: [NSLayoutConstraint]!
    
    let animationDuration = 0.5
    let animLG = UILayoutGuide()

    var pref: Preference!   {   didSet  {   tb.items![2].isEnabled = pref.numPositions > 0  }   }
    var isAnimating = false {   didSet  {   animationVC.isAnimating = isAnimating   }   }
    var animationVC: AnimationViewController!
    var rolloverTimer: Timer?
    var curAnim: UIViewPropertyAnimator?
    
    var chiImageView: UIImageView   {   get {   return animationVC.chiIV }   }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tb.items![2].isEnabled = pref.canPlay
        tb.items![4].isEnabled = pref.canHiliteTrash
    }
    override func viewDidLoad() {
        let dd = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
        let f = dd.appendingPathComponent(positionFile)
        let p = NSKeyedUnarchiver.unarchiveObject(withFile: f.path) as? Preference
        
        view.addLayoutGuide(animLG)
        
        // constraints for layout guide
        let layoutInsets = view.layoutMargins
        let topG = animLG.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 0)
        let bottomG = animLG.bottomAnchor.constraint(equalTo: tb.topAnchor, constant: 0)
        let leftG = animLG.leftAnchor.constraint(equalTo: view.leftAnchor, constant: layoutInsets.left)
        let rightG = animLG.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -layoutInsets.right)
        NSLayoutConstraint.activate([topG, bottomG, leftG, rightG])
        
        let width = animationView.widthAnchor.constraint(equalTo: animLG.widthAnchor, constant: -(layoutInsets.right + layoutInsets.left))
        let height = animationView.heightAnchor.constraint(equalTo: animLG.heightAnchor, constant: -(layoutInsets.bottom + layoutInsets.top))
        constraintsForFullChiView.append(contentsOf: [width, height])
        
        pref = p ?? Preference(transfer: nil, imageIndex: nil, trendText: [ "" ], targetText: [ "" ], segments: nil, numPositions: 1)
        animationVC.pref = pref
        if let d = pref.chiTransferImage {
            chiImageView.image = UIImage(data: d)
        }
    }
    
    // MARK: - Tool Bar -
    @IBAction func trash(_ sender: Any) {
        let ac = UIAlertController()
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        let deleteChi = UIAlertAction(title: "Delete Transfer Image", style: .destructive)
        {
            (_) in
            let f = Preference.DocDir.appendingPathComponent(chiImageFile)

            self.pref.chiTransferImage = nil
            self.chiImageView.image = nil
            NSKeyedArchiver.archiveRootObject(self.pref.chiTransferImage as Any, toFile: f.path)

            self.tb.items![2].isEnabled = self.pref.canPlay
            self.tb.items![4].isEnabled = self.pref.canHiliteTrash
        }
        let deleteRollover = UIAlertAction(title: "Delete Rollver Images", style: .destructive)
        {
            (_) in
            let f = Preference.DocDir.appendingPathComponent(positionFile)
            
            self.pref.removeAll()
            NSKeyedArchiver.archiveRootObject(self.pref, toFile: f.path)
            
            self.tb.items![2].isEnabled = self.pref.canPlay
            self.tb.items![4].isEnabled = self.pref.canHiliteTrash
        }
        
        if let vc = ac.popoverPresentationController {
            vc.barButtonItem = trashItem
        }
        
        ac.addAction(cancel)
        if pref.hasChiImage {
            ac.addAction(deleteChi)
        }
        if pref.hasTransferSequence {
            ac.addAction(deleteRollover)
        }
        present(ac, animated: true)
    }
    @IBAction func playRollover(_ playBtn: UIBarButtonItem) {
        let willBeAnimating = !isAnimating
        let pt1 = CGPoint(x: 0.1, y: 1.0)
        let pt2 = CGPoint(x: 0.5, y: 1.0)
        let playOrPauseAnimation = UIViewPropertyAnimator(duration: willBeAnimating ? 2 : 5, controlPoint1: pt1, controlPoint2: pt2) {
            if willBeAnimating {
                NSLayoutConstraint.deactivate(self.constraintsForReducedChiView)
                NSLayoutConstraint.activate(self.constraintsForFullChiView)
                NSLayoutConstraint.deactivate(self.animationVC.constraintsForPauseAnimation)
            } else {
                NSLayoutConstraint.deactivate(self.constraintsForFullChiView)
                NSLayoutConstraint.activate(self.constraintsForReducedChiView)
                NSLayoutConstraint.activate(self.animationVC.constraintsForPauseAnimation)
            }
            self.view.layoutIfNeeded()
        }
        if willBeAnimating {
            playOrPauseAnimation.addCompletion {
                _ in
                DispatchQueue.main.async {
                    Preference.curRolloverPosition = 0
                    self.animationVC.pref = self.pref
                    self.rolloverTimer = Timer.scheduledTimer(timeInterval: 3, target: self.animationVC, selector: #selector(AnimationViewController.animate(t:)), userInfo: self.pref, repeats: true)
                    self.rolloverTimer?.fire()
                }
            }
        }
        else {
            rolloverTimer?.invalidate()
            rolloverTimer = nil
        }
        
        if !willBeAnimating {
            UIView.transition(with: self.animationVC.targetTextLabel, duration: self.animationDuration,
                              options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                              animations: { self.animationVC.targetTextStack.isHidden = !willBeAnimating },
                              completion: nil)
            UIView.transition(with: self.animationVC.trendTextLabel, duration: self.animationDuration,
                              options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                              animations: { self.animationVC.trendTextStack.isHidden = !willBeAnimating },
                              completion: nil)
            playOrPauseAnimation.addCompletion {
                _ in
                DispatchQueue.main.async {
                    UIView.transition(with: self.animationVC.targetTextLabel, duration: self.animationDuration,
                                      options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                                      animations: { self.animationVC.targetTextStack.isHidden = !willBeAnimating },
                                      completion: nil)
                    UIView.transition(with: self.animationVC.trendTextLabel, duration: self.animationDuration,
                                      options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromLeft :  UIViewAnimationOptions.transitionFlipFromRight,
                                      animations: { self.animationVC.trendTextStack.isHidden = !willBeAnimating },
                                      completion: nil)
                    UIView.transition(with: self.animationVC.rolloverIV,
                                      duration: willBeAnimating ? 0 : self.animationDuration / 0.75,  // make transition without animations if willBeAnimating
                        options: UIViewAnimationOptions.transitionFlipFromRight,
                        animations: {  self.animationVC.rolloverIV.image = nil  })
                    
                }
            }
        }

        UIView.transition(with: self.animationVC.rolloverIV,
                          duration: willBeAnimating ? 0 : animationDuration * 0.75,  // make transition without animations if willBeAnimating
            options: willBeAnimating ? UIViewAnimationOptions.transitionFlipFromRight : UIViewAnimationOptions.curveLinear,
            animations: { if willBeAnimating { self.animationVC.rolloverIV.image = nil }  },
            completion:
            {
                _ in
                DispatchQueue.main.async {
                    if willBeAnimating { self.animationVC.rolloverStack.isHidden = !willBeAnimating }
                }
        })
        curAnim?.stopAnimation(!willBeAnimating)
        curAnim = playOrPauseAnimation
        playOrPauseAnimation.startAnimation()
        
        tb.items![0].isEnabled = !willBeAnimating
        tb.items![4].isEnabled = !willBeAnimating
        tb.items![2] = UIBarButtonItem(barButtonSystemItem: willBeAnimating ? UIBarButtonSystemItem.pause : UIBarButtonSystemItem.play, target: self, action: #selector(RolloverViewController.playRollover(_:)))
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

