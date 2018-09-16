//
//  ZACImageDownloader.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/16/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

class ZACImageDownloader: NSObject {
    
    
    
    private static var sharedImageDownloader: ZACImageDownloader = {
        let imageDownloader: ZACImageDownloader = ZACImageDownloader()
        return imageDownloader
    }()
    
    private override init() {
        super.init()
    }
    
    private class func shared() -> ZACImageDownloader {
        return self.sharedImageDownloader
    }
}
