//
//  ZACSearchResultItem.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

/**
 Each ZACSearchResultItem represents one listing.
 Do not create your own instances, these are given to you by the delegate callback of ZACNetworkManager or by calling ZACNetworkManager.currentlyFetchedListings().
 */
class ZACSearchResultItem: NSObject, Codable {
    var bathrooms: Int?  // Number of bathrooms
    var bedrooms: Int?  // Number of bedrooms
    var city: String?  // City Name
    var id: String?  // Unique identifier for the listing
    var listingType: String?  // Either "for sale" or "for rent"
    var latitude: Double?  // Location latitude
    var longitude: Double?  // Location longitude
    var neighborhood: String?  // Neighborhood name
    var numberOfPhotos: Int?  // Number of photos in the “photos” array
    var price: Int?  // Price in USD
    var propertyType: String?  // e.g. "Single-Family Home"
    var squareFeet: Int?  // Number of square feet inside the home
    var stateCode: String?  // The two letter state code the property is located in
    var streetName: String?  // The street name the property is located at
    var streetNumber: String?  // The street number, e.g. the “123” in “123 Main St.”
    var zipCode: String?  // The zip code of the property
    var photos: [String]?  // An array of URLs of property photos
}
