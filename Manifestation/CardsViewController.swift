//
//  CardsViewController.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 5/7/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class CardsViewController: UICollectionViewController {
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let img = UIImage(named: "AoD/\(indexPath.row - 1)")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as! CardCollectionViewCell
        
        cell.imageView.image = img
        return cell
        
    }
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let img = UIImage(named: "AoD/\(indexPath.row)")
        
        (cell as! CardCollectionViewCell).imageView.image = img
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AoDCount
    }
    
    @IBAction func back(_ sender: Any) {
    }
}
