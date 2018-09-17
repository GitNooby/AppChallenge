//
//  ZACImageCacher.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/16/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

class LinkedListNode: NSObject {
    var sha256Key: String
    var value: URL
    var next: LinkedListNode?
    var previous: LinkedListNode?
    
    init(_ sha256Key: String, value: URL) {
        self.sha256Key = sha256Key
        self.value = value
        super.init()
    }
    
}

class ZACImageCacher: NSObject {
    
    // Evection rule: LRU Cacher
    var linkedListHead: LinkedListNode?  // head is least recently used
    var linkedListTail: LinkedListNode?  // tail is most recently used
    var hashTable: [String: LinkedListNode] = [:]  // for quick access
    
    var maxCacheSize: Int = 200
    var currentCacheSize: Int = 0
    
    var applicationSupportURL: URL?
    
    private static var sharedImageCacher: ZACImageCacher = {
        return ZACImageCacher()
    }()
    
    private override init() {
        // get the application suppory directory
        do {
            let fileManager = FileManager.default
            let applicationSupportURL = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            self.applicationSupportURL = applicationSupportURL
        } catch {
            assert(false, "We can't get url to applicationSupportDirectory")  // TODO: should be graceful?
        }
        
        super.init()
    }
    
    private class func shared() -> ZACImageCacher {
        return self.sharedImageCacher
    }
    
    class func cacheImage(_ imageFileURL: URL, withKey key: String ) {
        
        let attr = try? FileManager.default.attributesOfItem(atPath: imageFileURL.path)
        let fileSize = attr![FileAttributeKey.size] as! UInt64
        if fileSize == 0 {
            return
        }
        
        let sha256Key: String = key.sha256()
        
        let imageCacher = ZACImageCacher.shared()
        
        if imageCacher.hashTable[sha256Key] != nil {
            return
        }
        
        do {
            let newURL: URL = URL(string: sha256Key, relativeTo: imageCacher.applicationSupportURL)!
            try FileManager.default.moveItem(at: imageFileURL, to: newURL)
            
            let node: LinkedListNode = LinkedListNode(sha256Key, value: newURL)
            imageCacher.hashTable[sha256Key] = node
            
            if imageCacher.currentCacheSize == 0 {
                imageCacher.linkedListHead = node
                imageCacher.linkedListTail = node
                imageCacher.currentCacheSize += 1
            }
            else if imageCacher.currentCacheSize < imageCacher.maxCacheSize {
                imageCacher.linkedListTail?.next = node
                node.previous = imageCacher.linkedListTail
                imageCacher.linkedListTail = node
                imageCacher.currentCacheSize += 1
            }
            else if imageCacher.currentCacheSize >= imageCacher.maxCacheSize {
                imageCacher.linkedListTail?.next = node
                node.previous = imageCacher.linkedListTail
                imageCacher.linkedListTail = node
                
                let nodeToDelete = imageCacher.hashTable[(imageCacher.linkedListHead?.sha256Key)!]
                imageCacher.deleteNodeFile(nodeToDelete!)
                imageCacher.hashTable[(imageCacher.linkedListHead?.sha256Key)!] = nil
                imageCacher.linkedListHead = imageCacher.linkedListHead?.next
                
            }
        }
        catch let error as NSError {
            assert(false, "TODO: this should be graceful: \(error.localizedDescription)")
        }

    }
    
    class func fetchImage(_ key: String) -> UIImage? {
        let sha256Key: String = key.sha256()
        let imageCacher = ZACImageCacher.shared()
        let node = imageCacher.hashTable[sha256Key]
        
        if node == nil {
            return nil
        }
        
        let image = UIImage(contentsOfFile: (node?.value.path)!)
        
        return image
    }
    
    class func clearCache() {
        let imageCacher = ZACImageCacher.shared()
        
        // Disconnect the linked list so the nodes can be released
        for (_, node) in imageCacher.hashTable {
            if node.previous != nil && node.next != nil {
                node.previous?.next = node.next
                node.next?.previous = node.previous
            }
            else if node.previous != nil && node.next == nil {
                assert(node == imageCacher.linkedListTail, "Error state for linked list")
                node.previous?.next = nil
                imageCacher.linkedListTail = node.previous
                node.previous = nil
            }
            else if node.next != nil && node.previous == nil {
                assert(node == imageCacher.linkedListHead, "Error state for linked list")
                node.next?.previous = nil
                imageCacher.linkedListHead = node.next
                node.next = nil
            }
        }
        
        // Clear the hashtable to release all nodes
        imageCacher.hashTable.removeAll()
        
        imageCacher.clearAllFilesFromApplicationSupportDirectory()
    }
    
    private func deleteNodeFile(_ node: LinkedListNode) {
        try? FileManager.default.removeItem(at: node.value)
    }
    
    private func clearAllFilesFromApplicationSupportDirectory(){
        let directoryContents: Array? = try? FileManager.default.contentsOfDirectory(atPath: self.applicationSupportURL!.path)
        
        if let directoryContents = directoryContents {
            for path in directoryContents {
                let fileURL = self.applicationSupportURL?.appendingPathComponent(path)
                try? FileManager.default.removeItem(at: fileURL!)
            }
        }
    }
}

extension String {
    
    func sha256() -> String{
        if let stringData = self.data(using: String.Encoding.utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
    
}
