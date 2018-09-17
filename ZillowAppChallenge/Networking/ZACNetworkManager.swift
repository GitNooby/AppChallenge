//
//  ZACNetworkManager.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

protocol ZACNetworkManagerDelegate: class {
    func networkManager(_ networkManager: ZACNetworkManager, fetchedResults results: [ZACSearchResultItem])
}

class ZACNetworkManager: NSObject {

    weak var delegate: ZACNetworkManagerDelegate?  // TODO: should be an array so that we can register multiple delegates
    var networkAPIEndPointURL: URLComponents?
    var incompleteTasksDataDictionary: [Int : Data]?  // Key is URLSessionDataTask's taskIdentifier
    var urlSession: URLSession?
    var searchResultItemsArray: [ZACSearchResultItem]?
    var searchResultItemsDictionary: [String: ZACSearchResultItem]?  // Key is property's identifier string
    
    // Properties for tracking paging
    var pageNumber: Int = 0  // starting at page 0
    var pageItemsCount: Int = 100  // Load 100 properties at a time
    
    // MARK: - Singleton
    
    private static var sharedNetworkManager: ZACNetworkManager = {
        // TODO: this url should not be hard coded
        let endpointURL: URLComponents! = URLComponents(string: "https://trulia-interview-challenge.herokuapp.com/listings")
        let networkManager: ZACNetworkManager = ZACNetworkManager(networkAPIEndPointURL: endpointURL)
        return networkManager
    }()
    
    private init(networkAPIEndPointURL: URLComponents) {
        super.init()
        self.networkAPIEndPointURL = networkAPIEndPointURL
        self.incompleteTasksDataDictionary = [:]
        // TODO: maybe this urlSeesion should be created as a background session instead of default
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.searchResultItemsArray = []
        self.searchResultItemsDictionary = [:]
    }
    
    private class func shared() -> ZACNetworkManager {
        return self.sharedNetworkManager
    }
    
    class func registerDelegate(_ delegate: ZACNetworkManagerDelegate) {
        ZACNetworkManager.shared().delegate = delegate
    }
    
    class func asyncFetchMoreListings() -> Progress {
        let sharedNetworkManager = ZACNetworkManager.shared()
        
        var fetchListingRequest = URLComponents(string: (sharedNetworkManager.networkAPIEndPointURL?.string)!)
        fetchListingRequest?.queryItems = [
            URLQueryItem(name: "start", value: String(sharedNetworkManager.pageNumber)),
            URLQueryItem(name: "count", value: String(sharedNetworkManager.pageItemsCount))
        ]
        
        let request = URLRequest(url: (fetchListingRequest?.url)!)
        let fetchListingDataTask: URLSessionDataTask = (sharedNetworkManager.urlSession?.dataTask(with: request))!
        fetchListingDataTask.taskDescription = "FetchListingsTask"  // TODO: should not hard code this string
        
        sharedNetworkManager.incompleteTasksDataDictionary![fetchListingDataTask.taskIdentifier] = Data()
        fetchListingDataTask.resume()
        
        return fetchListingDataTask.progress
    }
    
    class func fetchedListings() -> [ZACSearchResultItem] {
        return ZACNetworkManager.shared().searchResultItemsArray!
    }
    
}

extension ZACNetworkManager: URLSessionDelegate {
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if session == self.urlSession {
            self.urlSession = nil;  // Breaking retain cycle since URLSession holds a strong delegate
        }
    }

//    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
//        // TODO: we'll think about turning this into a background session later
//    }
}

extension ZACNetworkManager: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        // TODO: indicate that we have no connection
        print("taskIsWaitingForConnectivity \(task.taskIdentifier)")
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("URLSessionTask failure: \(error.localizedDescription)")
        }
        else if task.taskDescription == "FetchListingsTask" {
            self.pageNumber = self.pageNumber + self.pageItemsCount  // Increment page for future fetch
            
            let fetchedData = self.incompleteTasksDataDictionary![task.taskIdentifier]!
            let fetchedJSON = try? JSONSerialization.jsonObject(with: fetchedData, options: [])
            
            if let listings = fetchedJSON as? [Dictionary<String, Any>] {
                let jsonDecoder = JSONDecoder()
                for aListing in listings {
                    let encodedData = try? JSONSerialization.data(withJSONObject: aListing, options: .prettyPrinted)
                    let decodedListing = try? jsonDecoder.decode(ZACSearchResultItem.self, from: encodedData!)
                    if let decodedListing = decodedListing {
                        
                        if self.searchResultItemsDictionary![decodedListing.id!] == nil {
                            self.searchResultItemsArray?.append(decodedListing)
                            self.searchResultItemsDictionary![decodedListing.id!] = decodedListing
                        }
                    }
                }
                if self.delegate != nil {
                    DispatchQueue.main.async {
                        self.delegate?.networkManager(self, fetchedResults: self.searchResultItemsArray!)
                    }
                }
            }
        }
        self.incompleteTasksDataDictionary![task.taskIdentifier] = nil
    }
}

extension ZACNetworkManager: URLSessionDataDelegate {
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
//
//    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if dataTask.taskDescription == "FetchListingsTask" {
            self.incompleteTasksDataDictionary![dataTask.taskIdentifier]?.append(data)
        }
    }

//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {
//
//    }
}

//extension ZACNetworkManager: URLSessionDownloadDelegate {
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//
//    }
//
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//
//    }
//
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
//
//    }
//}








