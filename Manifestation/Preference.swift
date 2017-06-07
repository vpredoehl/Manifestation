//
//  Preference.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/6/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import Foundation


class Preference: NSObject, NSCoding {
    
    // MARK: Properties -
    private var imageIndex: [Int?]!
    private var trendText: [String]!
    private var targetText: [String]!
    var numPositions: Int
    
    init?(imageIndex ii: [Int?]?, trendText tr: [String]?, targetText ta: [String]?, numPositions n: Int) {
        if tr == nil || ta == nil {
            return nil
        }
        imageIndex = ii ?? [ nil, nil, nil ]
        trendText = tr
        targetText = ta
        numPositions = n
    }
    
    // MARK: - Archiving -
    func encode(with aCoder: NSCoder) {
        aCoder.encode(imageIndex, forKey: "imageIndex")
        aCoder.encode(trendText, forKey: "trendText")
        aCoder.encode(targetText, forKey: "targetText")
        aCoder.encode(numPositions, forKey: "numPositions")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let imageIndex = aDecoder.decodeObject(forKey: "imageIndex") as? [Int?]
        let trendText = aDecoder.decodeObject(forKey: "trendText") as? [String]
        let targetText = aDecoder.decodeObject(forKey: "targetText") as? [String]
        let numPositions = aDecoder.decodeInteger(forKey: "numPositions")
        
        self.init(imageIndex: imageIndex, trendText: trendText, targetText: targetText, numPositions: numPositions)
    }
    
    // MARK: - Accessors -
    func userText(forRow r: Int, ofType t: SegmentType) -> String {
        switch t {
        case .trend:
            return trendText[r]
        case .target:
            return targetText[r]
        }
    }
    
    func rolloverIndex(forRow r: Int) -> Int? {
        return imageIndex[r]
    }
    
    func remove(at rowToDelete: Int) {
        imageIndex.remove(at: rowToDelete)
        trendText.remove(at: rowToDelete)
        targetText.remove(at: rowToDelete)
        numPositions = numPositions - 1
    }
    
    func swap(fromRow: Int, to toRow: Int) {
        let tempIdx = imageIndex[toRow]
        let tempTrendText = trendText[toRow]
        let tempTargetText = targetText[toRow]
        
        imageIndex[toRow] = imageIndex[fromRow]
        trendText[toRow] = trendText[fromRow]
        targetText[toRow] = targetText[fromRow]
        
        imageIndex[fromRow] = tempIdx
        trendText[fromRow] = tempTrendText
        targetText[fromRow] = tempTargetText

    }
    
    func setText(text: String, forRow r: Int, ofType t: SegmentType) {
        switch t {
        case .trend:
            trendText[r] = text
        case .target:
            targetText[r] = text
        }
    }
    
    func setImageIndex(index i: Int, forRow r: Int) {
        imageIndex[r] = i
    }
}
