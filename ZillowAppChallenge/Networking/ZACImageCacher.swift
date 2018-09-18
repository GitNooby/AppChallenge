//
//  ZACImageCacher.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/16/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

/**
 ImageCacher caches images to memory.
 ImageCacher should be treated as a singleton.
 ImageCacher does NOT maintain state between app launches, so all cached images are lost after app quits.
 Cache evection rule: LRU
 */
class ZACImageCacher: NSObject {

    // Caching to memory
    private var memoryCacheLinkedList: LinkedList = LinkedList()  // head is least recently used
    private var memoryCacheHashTable: [String: LinkedListNode] = [:]  // for quick access
    private var maxMemoryCacheSize: Int = Constants.ImageCacher.maxMemoryCacheSize
    // Serial DispatchQueue to ensure only one thread is modifying the cache at a time
    private let serialLockQueue: DispatchQueue = DispatchQueue(label: "com.kaizou.ZillowAppChallenge.ZACImageCacherSerialQueue")
    
    // Mark: LRU cache interface
    
    class func clearCache() {
        // Ensure only one thread is modifying the cache
        sharedImageCacher.serialLockQueue.sync { [weak sharedImageCacher] in
            // Clear memory cache
            sharedImageCacher?.memoryCacheLinkedList.removeAllNodes()
            sharedImageCacher?.memoryCacheHashTable.removeAll()
        }
    }
    
    class func cacheImage(_ image:UIImage?, withKey key: String ) {
        if image == nil {
            return
        }
        
        // Ensure only one thread is modifying the cache
        sharedImageCacher.serialLockQueue.sync { [weak sharedImageCacher] in
            
            if let cachedImageNode = sharedImageCacher?.memoryCacheHashTable[key] {
                sharedImageCacher?.memoryCacheLinkedList.addNodeToTail((sharedImageCacher?.memoryCacheLinkedList.removeNode(cachedImageNode))!)
            }
            else {
                // Create a new node and add it to the cache
                let cachedImageNode: LinkedListNode = LinkedListNode(key, image: image!)
                sharedImageCacher?.memoryCacheLinkedList.addNodeToTail(cachedImageNode)
                sharedImageCacher?.memoryCacheHashTable[key] = cachedImageNode
                // Enfoce cache LRU eviction rule
                if (sharedImageCacher?.memoryCacheHashTable.count)! > (sharedImageCacher?.maxMemoryCacheSize)! {
                    let removedNode = sharedImageCacher?.memoryCacheLinkedList.removeNodeFromHead()
                    sharedImageCacher?.memoryCacheHashTable[(removedNode?.key)!] = nil
                }
            }
        }
    }
    
    class func fetchImage(_ key:String, completion: @escaping (_ image: UIImage?) -> Void ) {
        sharedImageCacher.serialLockQueue.sync { [weak sharedImageCacher] in
            
            // Try to fetch from memory first
            if let node = sharedImageCacher?.memoryCacheHashTable[key] {
                sharedImageCacher?.memoryCacheLinkedList.addNodeToTail(node)
                completion(node.image)
                return
            }
            completion(nil)
        }
    }
    
    // MARK: - Private
    
    private static var sharedImageCacher: ZACImageCacher = {
        return ZACImageCacher()
    }()
    
    private override init() {
        super.init()
    }
    
}

fileprivate class LinkedListNode: NSObject {
    var key: String
    var image: UIImage
    var next: LinkedListNode?
    var previous: LinkedListNode?
    
    init(_ key: String, image: UIImage) {
        self.key = key
        self.image = image
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
