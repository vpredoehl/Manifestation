//
//  Preference.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/6/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import Foundation

class Preference: NSObject, NSCoding, NSCopying {
    
    // MARK: Properties -
    private var imageIndex: [Int?]!
    private var trendText: [String]!
    private var targetText: [String]!
    private var selectedSegment: [SegmentType]!
    var chiTransferImage: Data? = nil
    
    var numPositions: Int
    
    init?(transfer t: Data?, imageIndex ii: [Int?]?, trendText tr: [String]?, targetText ta: [String]?, segments s: [SegmentType]?, numPositions n: Int) {
        if tr == nil || ta == nil {
            return nil
        }
        chiTransferImage = t
        imageIndex = ii ?? [ nil ]
        trendText = tr
        targetText = ta
        selectedSegment = s ?? [ SegmentType.trend ]
        numPositions = n
    }
    
    // MARK: - Archiving -
    func encode(with aCoder: NSCoder) {
        aCoder.encode(chiTransferImage, forKey: "chiImage")
        aCoder.encode(imageIndex, forKey: "imageIndex")
        aCoder.encode(trendText, forKey: "trendText")
        aCoder.encode(targetText, forKey: "targetText")
        aCoder.encode(toRawValue(), forKey: "selectedSegment")
        aCoder.encode(numPositions, forKey: "numPositions")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let transferImage = aDecoder.decodeObject(forKey: "chiImage") as? Data
        let imageIndex = aDecoder.decodeObject(forKey: "imageIndex") as? [Int?]
        let trendText = aDecoder.decodeObject(forKey: "trendText") as? [String]
        let targetText = aDecoder.decodeObject(forKey: "targetText") as? [String]
        let ss = aDecoder.decodeObject(forKey: "selectedSegment") as? [Int]
        let numPositions = aDecoder.decodeInteger(forKey: "numPositions")
        var st: [SegmentType]? = nil
        
        if ss != nil {
            st = [SegmentType]()
            for v in ss! {
                st!.append(SegmentType(rawValue: v)!)
            }
        }
        
        self.init(transfer: transferImage, imageIndex: imageIndex, trendText: trendText, targetText: targetText, segments: st, numPositions: numPositions)
    }
    
    private
    func toRawValue() -> [Int] {
        var ss = [Int]()
        for v in selectedSegment {
            ss.append(v.rawValue)
        }
        return ss
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
    
    func segment(forRow r: Int) -> SegmentType {
        return selectedSegment[r]
    }
    
    func remove(at rowToDelete: Int) {
        imageIndex.remove(at: rowToDelete)
        trendText.remove(at: rowToDelete)
        targetText.remove(at: rowToDelete)
        selectedSegment.remove(at: rowToDelete)
        numPositions -= 1
    }
    
    func add() {
        imageIndex.append(nil)
        trendText.append("")
        targetText.append("")
        selectedSegment.append(.trend)
        numPositions += 1
    }
    
    func move(fromRow: Int, to toRow: Int) {
        let tempIdx = imageIndex[fromRow]
        imageIndex.remove(at: fromRow)
        imageIndex.insert(tempIdx, at: toRow)
        
        let tempTrendText = trendText[fromRow]
        trendText.remove(at: fromRow)
        trendText.insert(tempTrendText, at: toRow)
        
        let tempTargetText = targetText[fromRow]
        targetText.remove(at: fromRow)
        targetText.insert(tempTargetText, at: toRow)
        
        let tempSS = selectedSegment[fromRow]
        selectedSegment.remove(at: fromRow)
        selectedSegment.insert(tempSS, at: toRow)
    }
    
    func set(text: String, forRow r: Int, ofType t: SegmentType) {
        switch t {
        case .trend:
            trendText[r] = text
        case .target:
            targetText[r] = text
        }
    }
    
    func set(segment s: SegmentType, forRow r: Int) {
        selectedSegment[r] = s
    }
    
    func set(imageIndex i: Int, forRow r: Int) {
        imageIndex[r] = i
    }
    
    // MARK: - NSCopying -
    func copy(with zone: NSZone? = nil) -> Any {
        return Preference(transfer: chiTransferImage, imageIndex: imageIndex, trendText: trendText, targetText: targetText, segments: selectedSegment, numPositions: numPositions)!
    }
}
