//
//  AnimationViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 7/21/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

extension Preference
{
    func rolloverForDisplay(forIndex i: Int) -> (UIImage, String, String) {
        let idx = rolloverIndex(forRow: i)!
        let img = Preference.userImages.image(forKey: String(idx))!
        let trend = trendText[i]
        let target = targetText[i]
        
        return (img, trend, target)
    }
}

class AnimationViewController: UIViewController
{
    @IBOutlet weak var chiIV: UIImageView!
    @IBOutlet weak var rolloverIV: UIImageView!
    @IBOutlet weak var rolloverStack: UIStackView!
    @IBOutlet weak var trendTextLabel: UILabel!
    @IBOutlet weak var targetTextLabel: UILabel!
    @IBOutlet weak var trendTextStack: UIStackView!
    @IBOutlet weak var targetTextStack: UIStackView!
    @IBOutlet var constraintsForPauseAnimation: [NSLayoutConstraint]!
    
    let inTransitionDuration = 0.4
    
    var pref: Preference!
    var isAnimating = false //{   didSet  {   rolloverStack.isHidden = !isAnimating    }  }
    var trendText: String!   {   didSet  {   trendTextLabel.text = trendText }   }
    var targetText: String! {   didSet  {   targetTextLabel.text = targetText   }   }
    
    override func viewDidLoad() {
        if let d = pref?.chiTransferImage {
            chiIV.image = UIImage(data: d)
        }
    }
    
    func animate() {
//        for i in 0..<pref.numPositions {
        let i = 0
            let (img, trend, target) = pref.rolloverForDisplay(forIndex: i)

        UIView.transition(with: rolloverIV, duration: inTransitionDuration * 0.75,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations: {    self.rolloverIV.image = img })

        UIView.transition(with: trendTextLabel, duration: inTransitionDuration,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations:
            {
                self.trendTextStack.isHidden = false
                self.trendTextLabel.text = trend
                self.trendTextLabel.sizeToFit()
                
        })
        UIView.transition(with: self.targetTextLabel, duration: inTransitionDuration,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations:
            {
                self.targetTextStack.isHidden = false
                self.targetTextLabel.text = target
                self.targetTextLabel.sizeToFit()
        })
        

//        }
    }
}
