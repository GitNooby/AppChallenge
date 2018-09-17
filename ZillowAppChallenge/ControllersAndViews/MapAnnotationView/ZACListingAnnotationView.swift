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
            self.image = UIImage(named: "iconMapMarker")
            self.canShowCallout = true
        }
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
