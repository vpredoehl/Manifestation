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
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        for pV in positionView {
            let pt = sender.location(in: pV)
            if pV.point(inside: pt, with: nil)
            {
                print("Position: \(imageIndex) selected.")
                pV.image = selectedImage
            }
        }
    }
}
