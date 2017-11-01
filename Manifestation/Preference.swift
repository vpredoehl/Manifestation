//
//  Preference.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/6/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import Foundation

let chiImageFile = "chiImage"
let positionFile = "positions"

class Preference: NSObject, NSCoding, NSCopying {
    
    // MARK: Properties -
    static let DocDir =
    {
        () -> URL in
        return FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    static var curRolloverPosition = 0

    open var imageIndex: [Int?]!
    open var trendText: [String]!
    open var targetText: [String]!
    static var userPhotoKeys: [Int]? = nil
    private var selectedSegment: [SegmentType]!
    var chiTransferImage: Data? = nil
    
    var numPositions: Int

    override convenience init()
    {
        self.init(transfer: nil, imageIndex: nil, trendText: [ "" ], targetText: [ "" ], segments: nil, numPositions: 1)!
    }
    
    init?(transfer t: Data?, imageIndex ii: [Int?]?, trendText tr: [String]?, targetText ta: [String]?, segments s: [SegmentType]?, numPositions n: Int) {
        if tr == nil || ta == nil {
            return nil
        }
        
        if let img = t {
            chiTransferImage = img
        }
        else {
            let f = Preference.DocDir.appendingPathComponent(chiImageFile)
            chiTransferImage = NSKeyedUnarchiver.unarchiveObject(withFile: f.path) as? Data
        }
        imageIndex = ii ?? [ nil ]
        trendText = tr
        targetText = ta
        selectedSegment = s ?? [ SegmentType.trend ]
        numPositions = n
    }
    
    // MARK: - Archiving -
    func encode(with aCoder: NSCoder) {
        aCoder.encode(imageIndex, forKey: "imageIndex")
        aCoder.encode(trendText, forKey: "trendText")
        aCoder.encode(targetText, forKey: "targetText")
        aCoder.encode(toRawValue(), forKey: "selectedSegment")
        aCoder.encode(numPositions, forKey: "numPositions")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        var imageIndex = aDecoder.decodeObject(forKey: "imageIndex") as? [Int?]
        let trendText = aDecoder.decodeObject(forKey: "trendText") as? [String]
        let targetText = aDecoder.decodeObject(forKey: "targetText") as? [String]
        let ss = aDecoder.decodeObject(forKey: "selectedSegment") as? [Int]
        let numPositions = aDecoder.decodeInteger(forKey: "numPositions")
        var st: [SegmentType]? = nil

        if let dirContents = try? FileManager.default.contentsOfDirectory(atPath: Preference.DocDir.path) {
            let userKeys = dirContents.filter { $0.starts(with: "UI-")  }
                .map { $0.components(separatedBy: "-").last! }
                .flatMap {    Int("-" + $0)    }
            
            Preference.userPhotoKeys = userKeys
        }

        // remove dangling user photo  indexes
        let docDir = Preference.DocDir
        imageIndex = imageIndex?.map
            {
                (idx) in
                guard let idx = idx else { return nil }
                guard idx < 0 else { return idx }
                let f = docDir.appendingPathComponent("UI\(idx)")
                return FileManager.default.fileExists(atPath: f.path) ? idx : nil
        }

        if ss != nil {
            st = [SegmentType]()
            for v in ss! {
                st!.append(SegmentType(rawValue: v)!)
            }
        }
        
        self.init(transfer: nil, imageIndex: imageIndex, trendText: trendText, targetText: targetText, segments: st, numPositions: numPositions)
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
    
    func rolloverIndex(forRow r: Int) -> (key: Int?, useCount: Int) {
        let key = imageIndex[r]
        let c = imageIndex.filter   {   $0 == key   }.count
        return (key, c)
    }
    
    func segment(forRow r: Int) -> SegmentType {
        return selectedSegment[r]
    }
    
    func remove(at rowToDelete: Int) {
        let kc = rolloverIndex(forRow: rowToDelete)
        if let idx = kc.key, kc.useCount == 1 {
            deleteImage(forKey: idx) // delete user image, if exists
        }
        imageIndex.remove(at: rowToDelete)
        trendText.remove(at: rowToDelete)
        targetText.remove(at: rowToDelete)
        selectedSegment.remove(at: rowToDelete)
        numPositions -= 1
    }
    
    func removeAll() {
        selectedSegment = [ SegmentType.trend ]
        imageIndex = [ nil ]
        trendText = [ "" ]
        targetText = [ "" ]
        numPositions = 1
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
        let kc = rolloverIndex(forRow: r)
        if let idx = kc.key, kc.useCount == 1 {
            deleteImage(forKey: idx)
        }
        imageIndex[r] = i
    }
    
    // MARK: - NSCopying -
    func copy(with zone: NSZone? = nil) -> Any {
        return Preference(transfer: chiTransferImage, imageIndex: imageIndex, trendText: trendText, targetText: targetText, segments: selectedSegment, numPositions: numPositions)!
    }
}
