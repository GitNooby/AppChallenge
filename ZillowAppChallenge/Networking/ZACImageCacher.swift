//
//  ZACImageCacher.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/16/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

fileprivate class LinkedListNode: NSObject {
    var sha256Key: String
    var originalKey: String
    var value: URL
    var image: UIImage?
    var next: LinkedListNode?
    var previous: LinkedListNode?
    
    init(_ sha256Key: String, originalKey: String, value: URL) {
        self.sha256Key = sha256Key
        self.originalKey = originalKey
        self.value = value
        super.init()
    }
}

fileprivate class LinkedList: NSObject {
    private var head: LinkedListNode?
    private var tail: LinkedListNode?
    
    func addNodeToTail(_ node: LinkedListNode) {
        if self.tail == nil && self.head == nil {
            self.tail = node
            self.head = node
            node.next = nil
            node.previous = nil
        }
        else if self.tail != nil {
            node.previous = self.tail
            node.next = nil
            self.tail?.next = node
            self.tail = node
        }
    }
    
    func removeNodeFromHead() -> LinkedListNode {
        return self.removeNode(self.head!)
    }
    
    func removeNode(_ node: LinkedListNode) -> LinkedListNode {
        if node.previous == nil && node.next == nil && self.tail == self.head && self.tail == node {
            self.head = nil
            self.tail = nil
        }
        else if node.previous != nil && node.next == nil {
            assert(node == self.tail, "Error state for linked list")
            node.previous?.next = nil
            self.tail = node.previous
            node.previous = nil
        }
        else if node.next != nil && node.previous == nil {
            assert(node == self.head, "Error state for linked list")
            node.next?.previous = nil
            self.head = node.next
            node.next = nil
        }
        else if node.previous != nil && node.next != nil {
            node.previous?.next = node.next
            node.next?.previous = node.previous
        }
        else {
            assert(false, "LinkedList error state")
        }
        node.next = nil
        node.previous = nil
        return node
    }
    
    func removeAllNodes() {
        while self.head != nil {
            _ = self.removeNode(self.head!)
        }
    }
    
}

class ZACImageCacher: NSObject {
    // Evection rule: LRU Cacher
    
    // Caching to disk
    private var diskCacheLinkedList: LinkedList = LinkedList() // head is least recently used
    private var diskCacheHashTable: [String: LinkedListNode] = [:]  // for quick access
    private var maxDiskCacheSize: Int = 100
    // Caching to memory
    private var memoryCacheLinkedList: LinkedList = LinkedList()  // head is least recently used
    private var memoryCacheHashTable: [String: LinkedListNode] = [:]  // for quick access
    private var maxMemoryCacheSize: Int = 20
    
    // Directory to save cached image files
    private var applicationSupportURL: URL?
    
    // Mark: LRU cache interface
    
    class func clearCache() {
        let imageCacher = ZACImageCacher.shared()
        
        // Clear memory cache
        imageCacher.memoryCacheLinkedList.removeAllNodes()
        imageCacher.memoryCacheHashTable.removeAll()
        
        // Clear disk cache
        imageCacher.diskCacheLinkedList.removeAllNodes()
        imageCacher.diskCacheHashTable.removeAll()

        // Remove all saved image files on disk
        imageCacher.clearAllFilesFromApplicationSupportDirectory()
    }
    
    class func cacheImage(_ imageFileURL: URL, withImage image:UIImage?, withKey key: String ) {
        // Only save files that are more than 0 bytes in size
        let attr = try? FileManager.default.attributesOfItem(atPath: imageFileURL.path)
        let fileSize = attr![FileAttributeKey.size] as! UInt64
        if fileSize == 0 {
            return
        }
        
        //  Convert all input keys to sha256 so we don't have to worry about weird characters in file names
        let sha256Key: String = key.sha256()
        let imageCacher = ZACImageCacher.shared()
        
        // If the file is already cached on disk, move it to tail to mark as most recently used
        if let nodeOnDisk = imageCacher.diskCacheHashTable[sha256Key] {
            imageCacher.diskCacheLinkedList.addNodeToTail(imageCacher.diskCacheLinkedList.removeNode(nodeOnDisk))
            
            if let nodeInMemory = imageCacher.memoryCacheHashTable[sha256Key] {
                imageCacher.memoryCacheLinkedList.addNodeToTail(imageCacher.memoryCacheLinkedList.removeNode(nodeInMemory))
            }
            else {
                // Create a new node for memory cache
                let memoryNode: LinkedListNode = LinkedListNode(nodeOnDisk.sha256Key, originalKey: nodeOnDisk.originalKey, value: nodeOnDisk.value)
                if nodeOnDisk.image == nil {
                    if image != nil {
                        memoryNode.image = image
                    }
                } else {
                    memoryNode.image = nodeOnDisk.image
                }
                imageCacher.memoryCacheLinkedList.addNodeToTail(memoryNode)
                imageCacher.memoryCacheHashTable[sha256Key] = memoryNode
                if imageCacher.memoryCacheHashTable.count > imageCacher.maxMemoryCacheSize {
                    let removedNode = imageCacher.memoryCacheLinkedList.removeNodeFromHead()
                    removedNode.image = nil
                    imageCacher.memoryCacheHashTable[removedNode.sha256Key] = nil
                }
            }
            return
        }
        else {
            // Move file to application support directory
            let newURL: URL = URL(string: sha256Key, relativeTo: imageCacher.applicationSupportURL)!
            do {
                try FileManager.default.moveItem(at: imageFileURL, to: newURL)
            }
            catch let error as NSError {
                assert(false, "TODO: this should be graceful: \(error.localizedDescription)")
            }
            
            // Create a new node for disk cache
            let diskNode: LinkedListNode = LinkedListNode(sha256Key, originalKey: key, value: newURL)
            // Disk cache LRU enforcement
            imageCacher.diskCacheLinkedList.addNodeToTail(diskNode)
            imageCacher.diskCacheHashTable[sha256Key] = diskNode
            if imageCacher.diskCacheHashTable.count > imageCacher.maxDiskCacheSize {
                let removedNode = imageCacher.diskCacheLinkedList.removeNodeFromHead()
                imageCacher.deleteFileForNode(removedNode)
                imageCacher.diskCacheHashTable[removedNode.sha256Key] = nil
            }
            
            // Create a new node for memory cache
            let memoryNode: LinkedListNode = LinkedListNode(sha256Key, originalKey: key, value: newURL)
            // Memory cache LRU enforcement
            imageCacher.memoryCacheLinkedList.addNodeToTail(memoryNode)
            imageCacher.memoryCacheHashTable[sha256Key] = memoryNode
            if imageCacher.memoryCacheHashTable.count > imageCacher.maxMemoryCacheSize {
                let removedNode = imageCacher.memoryCacheLinkedList.removeNodeFromHead()
                removedNode.image = nil
                imageCacher.memoryCacheHashTable[removedNode.sha256Key] = nil
            }
        }
    }
    
    class func fetchImage(_ key: String) -> UIImage? {
        //  Convert all input keys to sha256 so we don't have to worry about weird characters in file names
        let sha256Key: String = key.sha256()
        let imageCacher = ZACImageCacher.shared()
        
        // Try to fetch from memory first
        if let node = imageCacher.memoryCacheHashTable[sha256Key] {
            ZACImageCacher.cacheImage(node.value, withImage: node.image, withKey: node.originalKey)
            return node.image
        }
        else if let node = imageCacher.diskCacheHashTable[sha256Key] {
            let image = imageCacher.readImageFromDiskForNode(node)
            ZACImageCacher.cacheImage(node.value, withImage: image, withKey: node.originalKey)
            return image
        }
        return nil
    }
    
    // MARK: - Private
    
    private func readImageFromDiskForNode(_ node: LinkedListNode) -> UIImage {
        return UIImage(contentsOfFile: node.value.path)!
    }
    
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
    
    private func deleteFileForNode(_ node: LinkedListNode) {
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
