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
    func rolloverForDisplay() -> (UIImage?, String, String) {
        let trend = trendText[Preference.curRolloverPosition]
        let target = targetText[Preference.curRolloverPosition]
        let rolloverPosition = Preference.curRolloverPosition

        Preference.curRolloverPosition =
            Preference.curRolloverPosition == numPositions - 1
            ? 0
            : Preference.curRolloverPosition + 1

        guard let idx = rolloverIndex(forRow: rolloverPosition).key else
        {
            guard trend != "" || target != "" else {
                return rolloverForDisplay() // nothing to display in this position
            }
            return (nil, trend, target)
        }
        return (image(forKey: idx), trend, target)
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
    
    @objc
    func animate(t: Timer) {
        let pref = t.userInfo as! Preference
        let (img, trend, target) = pref.rolloverForDisplay()
        
        UIView.transition(with: rolloverIV, duration: inTransitionDuration * 0.75,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations: {    self.rolloverIV.image = img })
        
        UIView.transition(with: trendTextLabel, duration: inTransitionDuration,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations:
            {
                self.trendTextStack.isHidden = false
                self.trendTextLabel.text = trend == "" ? "<NOT SET>" : trend
                self.trendTextLabel.sizeToFit()
                
        })
        UIView.transition(with: self.targetTextLabel, duration: inTransitionDuration,
                          options: UIViewAnimationOptions.transitionFlipFromLeft,
                          animations:
            {
                self.targetTextStack.isHidden = false
                self.targetTextLabel.text = target == "" ? "<NOT SET>" : target
                self.targetTextLabel.sizeToFit()
        })
    }
}
