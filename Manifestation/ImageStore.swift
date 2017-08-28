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
        let url = imageURL(forKey: key)
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            try? data.write(to: url, options: [.atomic])
            if key < 0 {    // store user photo key
                if userPhotoKeys == nil {
                    userPhotoKeys = [ key ]
                }
                else {
                    userPhotoKeys!.append(key)
                }
                let photosF = Preference.DocDir.appendingPathComponent(tempPhotoKeysFile)
                NSKeyedArchiver.archiveRootObject(userPhotoKeys!, toFile: photosF.path)
            }
        }
        
        Preference.cache.setObject(image, forKey: String(key) as NSString)
    }
    
    func image(forKey key: Int) -> UIImage? {
        if let existingImage = Preference.cache.object(forKey: String(key) as NSString) {
            return existingImage
        }
        
        let url = imageURL(forKey: key)
        guard let imageFromDisk = UIImage(contentsOfFile: url.path)
            else    {   return nil  }
        Preference.cache.setObject(imageFromDisk, forKey: String(key) as NSString)
        return imageFromDisk
    }
    
    func deleteImage(forKey key: Int) {
        Preference.cache.removeObject(forKey: String(key) as NSString)
        
        let url = imageURL(forKey: key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch let deleteError  {  // implicit error constant if not specified
            print("Error removing image from disk \(deleteError)")
        }
    }
    
    func imageURL(forKey key: Int) -> URL {
        let docsDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = docsDirs.first!
        
        return docDir.appendingPathComponent("UI" + String(key))
    }
}
