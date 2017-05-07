//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class CardsViewController: UICollectionViewController {
    
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let img = UIImage(named: "AoD/\(indexPath.row)")
        
        (cell as! CardCollectionViewCell).imageView.image = img
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return AoDCount
    }
}
