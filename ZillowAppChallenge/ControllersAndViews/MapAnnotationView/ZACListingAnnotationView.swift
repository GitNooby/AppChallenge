//
//  ZACListingAnnotationView.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/16/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit
import MapKit

class ZACListingAnnotationView: MKAnnotationView {
    
    override var annotation: MKAnnotation? {
        willSet {
            self.image = UIImage(named: Constants.ImageAssetNames.iconMapMarker)
            self.canShowCallout = true
        }
    }

}
