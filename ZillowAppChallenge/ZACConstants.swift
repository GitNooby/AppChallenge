//
//  ZACConstants.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/17/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import Foundation

struct Constants {
    struct NetworkManager {
        static let pageSize: Int = 100  // the "count" of API endpoint parameter; fetch 100 items at a time
        static let endpointURL: URLComponents = URLComponents(string: "https://trulia-interview-challenge.herokuapp.com/listings")!
    }
    
    struct ImageCacher {
        static let maxMemoryCachedImages: Int = 100
    }
    
    struct ListingsTableView {
        static let listingResultCellID: String = "SearchResultItemCell"
    }
    
    struct ImageAssetNames {
        static let iconMapMarker = "iconMapMarker"
        static let iconMapView = "iconMapView"
        static let iconListView = "iconListView"
    }
}
