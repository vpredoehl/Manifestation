//
//  PositionViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let numPositions = 3

class PositionViewController: UIViewController {
    @IBOutlet var positionView: [UIImageView]!
    
    var selectedImage: UIImage!
    var imageIndex: Int!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.title = "Position"
    }
    
    override func viewDidLoad() {
        let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController
        
        for pV in positionView {
            if let idx = rolloverVC.rolloverImageIndex[pV.tag - 1] {
                pV.image = UIImage(named: "AoD/\(idx + 1)")
            }
        }

    }
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        for pV in positionView {
            let pt = sender.location(in: pV)
            if pV.point(inside: pt, with: nil)
            {
                let rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController
                let wellPosition = pV.tag
                
                print("Position: \(pV.tag) ImageIndex: \(imageIndex)")
                pV.image = selectedImage
                rolloverVC.rolloverImageIndex[wellPosition - 1] = imageIndex
            }
        }
    }
}
