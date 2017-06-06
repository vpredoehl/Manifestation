//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class CardsViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let insets = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        
        collectionView?.scrollIndicatorInsets = insets
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        navigationItem.title = "Cards"
    }

    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = UIImage(named: "AoD/\(indexPath.row + 1)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        
        cell.imageView.image = img
        cell.imgIdx = indexPath.row
        return cell
        
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AoDCount
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let cell = sender as? CardCollectionViewCell
//        let positionVC = segue.destination as! PositionViewController
//        
//        positionVC.selectedImage = cell?.imageView.image
//        positionVC.imageIndex = cell?.imgIdx
//        positionVC.rolloverVC = navigationController?.viewControllers.first! as! RolloverViewController
    }
}
