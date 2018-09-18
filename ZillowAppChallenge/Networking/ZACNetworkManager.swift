//
//  ZACNetworkManager.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

/**
 Conform to NetworkManager's delegate to receive property listing fetch results
 */
protocol ZACNetworkManagerDelegate: class {
    /**
     Callback for the shared NetworkManager to present network fetched results
     - Parameter networkManager: the shared NetworkManager
     - Parameter results: Array of fetched property listings
     */
    func networkManager(_ networkManager: ZACNetworkManager, fetchedResults results: [ZACSearchResultItem])
}

/**
 NetworkManager should only be treated as a singleton. Only call its class methods.
 */
class ZACNetworkManager: NSObject {

    weak var delegate: ZACNetworkManagerDelegate?
    private var incompleteTasksDataDictionary: [Int : Data]  // Key is URLSessionDataTask's taskIdentifier
    private var urlSession: URLSession?
    private var searchResultItemsArray: [ZACSearchResultItem]  // The array of fetched results
    private var searchResultItemsDictionary: [String: ZACSearchResultItem]  // Key is ZACSearchResultItem's id string
    private var pageNumber: Int  // Tracking paging
    
    // Resolve producer-consumer thread issue with serial queue
    private let serialLockQueue: DispatchQueue = DispatchQueue(label: "com.kaizou.ZillowAppChallenge.ZACNetworkManager")
    
    // MARK: - Public class functions
    
    class func registerDelegate(_ delegate: ZACNetworkManagerDelegate) {
        sharedNetworkManager.serialLockQueue.sync { [weak sharedNetworkManager] in
            sharedNetworkManager?.delegate = delegate
        }
    }
    
    class func fetchMoreListings() {
        sharedNetworkManager.serialLockQueue.sync { [weak sharedNetworkManager] in
            var fetchListingRequest = URLComponents(string: Constants.NetworkManager.endpointURL.string!)
            fetchListingRequest?.queryItems = [
                URLQueryItem(name: "start", value: String((sharedNetworkManager?.pageNumber)!)),
                URLQueryItem(name: "count", value: String(Constants.NetworkManager.pageSize))
            ]
            
            let request = URLRequest(url: (fetchListingRequest?.url)!)
            let fetchListingDataTask: URLSessionDataTask = (sharedNetworkManager?.urlSession?.dataTask(with: request))!
            fetchListingDataTask.taskDescription = "FetchListingsTask"  // TODO: should not hard code this string
            
            sharedNetworkManager?.incompleteTasksDataDictionary[fetchListingDataTask.taskIdentifier] = Data()
            fetchListingDataTask.resume()
        }
    }
    
    class func fetchedListings() -> [ZACSearchResultItem] {
        return sharedNetworkManager.serialLockQueue.sync { [weak sharedNetworkManager] in
            return sharedNetworkManager!.searchResultItemsArray
        }
    }
    
    // MARK: - Singleton private functions
    
    private static var sharedNetworkManager: ZACNetworkManager = {
        return ZACNetworkManager()
    }()
    
    private override init() {
        self.incompleteTasksDataDictionary = [:]
        self.searchResultItemsArray = []
        self.searchResultItemsDictionary = [:]
        self.pageNumber = 0
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
}

extension ZACNetworkManager: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        self.serialLockQueue.async { [weak self] in
            if let error = error {
                print("URLSessionTask failure: \(error.localizedDescription)")
            }
            else if task.taskDescription == "FetchListingsTask" {
                self?.pageNumber = (self?.pageNumber)! + Constants.NetworkManager.pageSize  // Increment page for future fetch
                
                let fetchedData = self?.incompleteTasksDataDictionary[task.taskIdentifier]!
                let fetchedJSON = try? JSONSerialization.jsonObject(with: fetchedData!, options: [])
                
                if let listings = fetchedJSON as? [Dictionary<String, Any>] {
                    let jsonDecoder = JSONDecoder()
                    for aListing in listings {
                        let encodedData = try? JSONSerialization.data(withJSONObject: aListing, options: .prettyPrinted)
                        let decodedListing = try? jsonDecoder.decode(ZACSearchResultItem.self, from: encodedData!)
                        if let decodedListing = decodedListing {
                            
                            if self?.searchResultItemsDictionary[decodedListing.id!] == nil {
                                self?.searchResultItemsArray.append(decodedListing)
                                self?.searchResultItemsDictionary[decodedListing.id!] = decodedListing
                            }
                        }
                    }
                    if self?.delegate != nil && listings.count > 0 {
                        DispatchQueue.main.async {
                            self?.delegate?.networkManager(self!, fetchedResults: (self?.searchResultItemsArray)!)
                        }
                    }
                }
            }
            self?.incompleteTasksDataDictionary[task.taskIdentifier] = nil
        }
    }
}

extension ZACNetworkManager: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if dataTask.taskDescription == "FetchListingsTask" {
            self.serialLockQueue.sync { [weak self] in
                self?.incompleteTasksDataDictionary[dataTask.taskIdentifier]?.append(data)
            }
        }
    }
}








