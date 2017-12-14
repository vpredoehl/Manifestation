//
//  ImageStore.swift
//  Homepwner
//
//  Created by Vincent Predoehl on 4/25/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

extension Preference
{
    static let cache = NSCache<NSString, UIImage>()

    func setImage(_ image: UIImage, forKey key: Int)
    {
        let matchesKey = RolloverPresets.userPhotoKeys?.filter   { $0 == key }
        let url = imageURL(forKey: key)
        
        guard key < 0 && (matchesKey == nil || matchesKey?.count == 0) else {  return } // ignore user images that are already saved
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            try? data.write(to: url, options: [.atomic])
            if key < 0 {    // store user photo key
                if RolloverPresets.userPhotoKeys == nil {
                    RolloverPresets.userPhotoKeys = [ key ]
                }
                else {
                    RolloverPresets.userPhotoKeys!.append(key)
                }
            }
        }
        
        Preference.cache.setObject(image, forKey: String(key) as NSString)
    }
    
    func image(forKey key: Int) -> UIImage? {
        if let existingImage = Preference.cache.object(forKey: String(key) as NSString) {
            return existingImage
        }
        let url = imageURL(forKey: key)
        
        guard let imageFromDisk = key < 0
            ? UIImage(contentsOfFile: url.path)
            : UIImage(named: "AoD/\(key + 1)")
            else { return nil }
        
        Preference.cache.setObject(imageFromDisk, forKey: String(key) as NSString)
        return imageFromDisk
    }
    
    func deleteUnusedImages() {
        for key in toBeDeleted {
            deleteImage(forKey: key, justCache: false)
        }
    }
    
    func deleteImage(forKey key: Int, justCache: Bool = true) {
        if justCache {
            toBeDeleted.append(key)
        } else {
            Preference.cache.removeObject(forKey: String(key) as NSString)
            if key < 0  && key & 1 == 1 {   // don't delete images taken by the camera
                let url = imageURL(forKey: key)
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let deleteError  {  // implicit error constant if not specified
                    print("Error removing image from disk \(deleteError)")
                }
                RolloverPresets.userPhotoKeys = RolloverPresets.userPhotoKeys?.filter {  $0 != key   }
            }

        }
    }
    
    func imageURL(forKey key: Int) -> URL {
        return Preference.AppDir.appendingPathComponent("UI\(key)")
    }
}
