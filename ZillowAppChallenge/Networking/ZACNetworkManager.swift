//
//  ZACNetworkManager.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

class ZACNetworkManager: NSObject {

    // MARK: - Singleton
    
    private static var sharedNetworkManager: ZACNetworkManager = {
        // TODO: this url should not be hard coded
        let endpointURL: URLComponents! = URLComponents(string: "https://trulia-interview-challenge.herokuapp.com/listings")
        
        let networkManager: ZACNetworkManager = ZACNetworkManager(networkAPIEndPointURL: endpointURL)
        return networkManager
    }()
    
    let networkAPIEndPointURL: URLComponents
    
    var dataTask: URLSessionDataTask?
    
    var urlSession: URLSession?
    
    var incompleteTasksData: [Int : Data]
    
    // MARK: - Inititalizer
    
    private init(networkAPIEndPointURL: URLComponents) {
        self.networkAPIEndPointURL = networkAPIEndPointURL;
        self.incompleteTasksData = [:]
        super.init()
        
        // TODO: maybe this should be created as a background session instead of default
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    class func shared() -> ZACNetworkManager {
        return self.sharedNetworkManager
    }
    
    func getPropertyList() -> Dictionary<String, Any>? {
        
        var request = URLComponents(string: self.networkAPIEndPointURL.string!)
        request?.queryItems = [URLQueryItem(name: "start", value: "0"), URLQueryItem(name: "count", value: "1")]
        
        let req = URLRequest(url: (request?.url)!)
        
        let dataTask: URLSessionDataTask = (self.urlSession?.dataTask(with: req))!
        
        
        self.incompleteTasksData[dataTask.taskIdentifier] = Data()
        
        dataTask.resume()
        
        return nil
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
        if error == nil {
//            print("didCompleteWithError? \(task.taskIdentifier)")
            
            let data = self.incompleteTasksData[task.taskIdentifier]!
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if let response = json as? [Dictionary<String, Any>] {
                for item in response {
//                    print("\(item)")
                    let asdfData = try? JSONSerialization.data(withJSONObject: item, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    let home = try? decoder.decode(ZACSearchResultItem.self, from: asdfData!)
                    print("\(home?.zipCode)")
                }
            }
            
        }
        else {
            print("catastrophic: \(error?.localizedDescription ?? "what")")
        }
        self.incompleteTasksData[task.taskIdentifier] = nil
    }
}

extension ZACNetworkManager: URLSessionDataDelegate {
//    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
//
//    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.incompleteTasksData[dataTask.taskIdentifier]!.append(data)
        print("didReceive Data \(dataTask.taskIdentifier)")
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








