//
//  Preference.swift
//  Manifestation
//
//  Created by Vincent Predoehl on 6/6/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

let chiImageFile = "chiImage"
let positionFile = "positions"
let presetsFile = "presets"

class RolloverPresets : NSObject {
    @objc dynamic var names: [String] = []
    var presetPref: [Preference] = []
    @objc dynamic var defaultPref: Preference? = nil
    var ctx = 0
    static var rp: RolloverPresets!     // reference to only instance of self
    
    override init() {
        super.init()
        RolloverPresets.rp = self
        let f = Preference.DocDir.appendingPathComponent(positionFile)
        
        defaultPref = Preference(fileURL: f)
        defaultPref!.open { (s) in
            if s {
                print("open OK")
            }
            else {
                print("open failed")
            }
        }


        if let dirContents = try? FileManager.default.contentsOfDirectory(at: Preference.AppDir, includingPropertiesForKeys: [.isDirectoryKey], options: .skipsHiddenFiles) {
            for preset in dirContents {
                if preset.hasDirectoryPath {
                    let posF = preset.appendingPathComponent(positionFile)
                    let pref = NSKeyedUnarchiver.unarchiveObject(withFile: posF.path) as! Preference
                    
                    names.append(preset.lastPathComponent)
                    presetPref.append(pref)
                }
            }
        }
    }
    
    func cleanImageCache(prefBeingDeleted p: Preference)  {
        for idx in p.imageIndex {
            guard let key = idx,
                key < 0,
                useCount(userImageIndex: key) == 1
                else { continue    }
            p.deleteImage(forKey: key, justCache: false)
        }
    }
    
    func useCount(userImageIndex key: Int?) -> Int {
        var c = defaultPref?.imageIndex.filter   {   $0 == key   }.count ?? 0
        
        for p in presetPref {
            let u = p.imageIndex.filter {   $0 == key   }.count
            c += u
        }
        return c
    }
    
    func index(of p: Preference) -> Int? {
        return presetPref.index(of: p)
    }
}

func ==(lhs: [Int?], rhs: [Int?]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    for i in 0..<lhs.count {
        if lhs[i] != rhs[i] {
            return false
        }
    }
    return true
}

class Preference: UIDocument, NSCoding, NSCopying {
    
    // MARK: Properties -
    static let DocDir =
    {
        () -> URL in
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }()
    static let AppDir = {
        () -> URL in
        return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }()
    static var curRolloverPosition = 0

    open var imageIndex: [Int?] = [ nil ]
    open var toBeDeleted: [Int] = []
    open var trendText: [String] = [ "" ]
    open var targetText: [String] = [ "" ]
    static var userPhotoKeys: [Int]? = nil
    private var selectedSegment: [SegmentType] = [ SegmentType.trend ]
    var numPositions: Int = 1
    
    var chiTransferImage: Data? = nil
    
    convenience init() {
        self.init(transfer: nil, imageIndex: nil, trendText: [ "" ], targetText: [ "" ], segments: nil, numPositions: 1)!
    }

    override init(fileURL url: URL) {
        super.init(fileURL: url)
        if FileManager.default.fileExists(atPath: url.path) {
            open { (s) in
                if s {
                    print("open OK")
                }
                else {
                    print("open failed")
                }
            }
        }
        else {
            save(to: url, for: .forCreating, completionHandler: { (s) in
                if s {
                    print("Save OK")
                }
                else {
                    print("Save failed")
                }
            })
        }
    }
    
    init?(transfer t: Data?, imageIndex ii: [Int?]?, trendText tr: [String]?, targetText ta: [String]?, segments s: [SegmentType]?, numPositions n: Int, fileURL url: URL? = nil) {
        let temp = Preference.AppDir.appendingPathComponent("temp")
        
        super.init(fileURL: url ?? temp)
        if tr == nil || ta == nil {
            return nil
        }
        
        if let img = t {
            chiTransferImage = img
        }
        else {
            let f = Preference.AppDir.appendingPathComponent(chiImageFile)
            chiTransferImage = NSKeyedUnarchiver.unarchiveObject(withFile: f.path) as? Data
        }
        imageIndex = ii ?? [ nil ]
        trendText = tr ?? [ "" ]
        targetText = ta ?? [ "" ]
        selectedSegment = s ?? [ SegmentType.trend ]
        numPositions = n
    }
    
    // MARK: - UIDocument
    override func contents(forType typeName: String) throws -> Any {
        return NSKeyedArchiver.archivedData(withRootObject:self)
    }
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        let p = NSKeyedUnarchiver.unarchiveObject(with: contents as! Data) as? Preference
        
        imageIndex = p?.imageIndex ?? [ nil ]
        trendText = p?.trendText ?? [ "" ]
        targetText = p?.targetText ?? [ "" ]
        selectedSegment = p?.selectedSegment ?? [ SegmentType.trend ]
        numPositions = p?.numPositions ?? 1
        
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
    
    func rolloverIndex(forRow r: Int, findUseCount: Bool = false) -> (key: Int?, useCount: Int) {
        let key = imageIndex[r]
        let c = findUseCount
            ? RolloverPresets.rp.useCount(userImageIndex: key)
            : 0
        return (key, c)
    }
    
    func segment(forRow r: Int) -> SegmentType {
        return selectedSegment[r]
    }
    
    func remove(at rowToDelete: Int) {
        let kc = rolloverIndex(forRow: rowToDelete, findUseCount: true)
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
        let kc = rolloverIndex(forRow: r, findUseCount: true)
        if let idx = kc.key, kc.useCount == 1 {
            deleteImage(forKey: idx)
        }
        imageIndex[r] = i
    }
    
    // MARK: - NSCopying -
    func copy(with zone: NSZone? = nil) -> Any {
        return Preference(transfer: chiTransferImage, imageIndex: imageIndex, trendText: trendText, targetText: targetText, segments: selectedSegment, numPositions: numPositions)!
    }

    override func isEqual(_ obj: Any?) -> Bool {
        guard let rhs = obj as? Preference else { return false }

        let eqII = imageIndex == rhs.imageIndex
        let eqTrend = trendText == rhs.trendText
        let eqTarget = targetText == rhs.targetText
        
        return eqII && eqTrend && eqTarget

    }
}


