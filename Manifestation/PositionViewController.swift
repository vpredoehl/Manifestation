//
//  PositionViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let numPositions = 3

class PositionViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    @IBOutlet var positionView: [UIImageView]!
    @IBOutlet weak var doubleTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var singleTapGesture: UITapGestureRecognizer!
    
    var selectedImage: UIImage!
    var imageIndex: Int!
    var rolloverVC: RolloverViewController!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.title = "Position"
    }
    
    override func viewDidLoad() {
        
        for pV in positionView {
            if let idx = rolloverVC.rolloverImageIndex[pV.tag - 1] {
                pV.image = UIImage(named: "AoD/\(idx + 1)")
            }
        }
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    @IBAction func switchSegment(_ sender: UISegmentedControl) {
        print("Switched Segment: \(sender.selectedSegmentIndex)")
    }
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        print("Taps: \(sender.numberOfTapsRequired)")
        for pV in positionView {
            let pt = sender.location(in: pV)
            if !pV.isHidden && pV.point(inside: pt, with: nil)
            {
                let wellPosition = pV.tag
                
                print("Position: \(pV.tag) ImageIndex: \(imageIndex)  numberOfTaps: \(sender.numberOfTapsRequired)")
                if sender.numberOfTapsRequired == 2 {
                    pV.image = nil
                    rolloverVC.rolloverImageIndex[wellPosition - 1] = nil
                } else {
                    pV.image = selectedImage
                    rolloverVC.rolloverImageIndex[wellPosition - 1] = imageIndex

                }
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
