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
    @IBOutlet weak var chiImageView: UIImageView!
    @IBOutlet weak var rolloverImageView: UIImageView!

    var rolloverImageIndex: [Int?] = [ nil, nil, nil ]
    var trendText = [ "", "", "" ]
    var targetText = [ "", "", "" ]
    var numPositions = maxNumPositions
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let dest = segue.destination as! PositionTableViewController
        
        dest.imageIndex = rolloverImageIndex
        dest.trendText = trendText
        dest.targetText = targetText
        dest.numPositions = numPositions
    }
}

