//
//  ImageStore.swift
//  Homepwner
//
//  Created by Vincent Predoehl on 4/25/17.
//  Copyright © 2017 Vincent Predoehl. All rights reserved.
//

import UIKit

class ImageStore
{
    let cache = NSCache<NSString, UIImage>()
    
    func setImage(_ image: UIImage, forKey key: String)
    {
        let url = imageURL(forKey: key)
        if let data = UIImageJPEGRepresentation(image, 0.5) {
            try? data.write(to: url, options: [.atomic])
        }
        
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        if let existingImage = cache.object(forKey: key as NSString) {
            return existingImage
        }
        
        let url = imageURL(forKey: key)
        guard let imageFromDisk = UIImage(contentsOfFile: url.path)
            else    {   return nil  }
        cache.setObject(imageFromDisk, forKey: key as NSString)
        return imageFromDisk
    }
    
    func deleteImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        
        let url = imageURL(forKey: key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch let deleteError  {  // implicit error constant if not specified
            print("Error removing image from disk \(deleteError)")
        }
    }
    
    func imageURL(forKey key: String) -> URL {
        let docsDirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docDir = docsDirs.first!
        
        return docDir.appendingPathComponent("UI" + key)
    }
}
