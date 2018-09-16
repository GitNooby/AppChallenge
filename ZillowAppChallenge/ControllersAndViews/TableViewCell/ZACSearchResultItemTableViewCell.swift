//
//  ZACSearchResultItemTableViewCell.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit

class ZACSearchResultItemTableViewCell: UITableViewCell {

    @IBOutlet weak var propertyImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var bedroomsLabel: UILabel!
    @IBOutlet weak var bathroomsLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func unpopulate() {
        self.propertyImageView.image = UIImage(named: "iconPhotoPlaceholder")

        self.addressLabel.isHidden = true
        self.addressLabel.text = nil
        
        self.priceLabel.isHidden = true
        self.priceLabel.text = nil
        
        self.bedroomsLabel.isHidden = true
        self.bedroomsLabel.text = nil
        
        self.bathroomsLabel.isHidden = true
        self.bathroomsLabel.text = nil
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    func populate(with model: ZACSearchResultItem) {
        // TODO: async grab the image
        self.propertyImageView.layer.borderColor = UIColor.red.cgColor
        self.propertyImageView.layer.borderWidth = 2
        
        self.addressLabel.isHidden = false
        self.addressLabel.text = "\(model.streetNumber ?? "--") \(model.streetName ?? "--"), \(model.city ?? "--"), \(model.stateCode ?? "--")"
        
        self.priceLabel.isHidden = false
        self.priceLabel.text = "$\(model.price ?? -1)"  // TODO: handle nils by printing "$ --" instead
        
        self.bedroomsLabel.isHidden = false
        self.bedroomsLabel.text = "\(model.bedrooms ?? -1) bds"  // TODO: handle nils by printing "-- bds" instead
        
        self.bathroomsLabel.isHidden = false
        self.bathroomsLabel.text = "\(model.bathrooms ?? -1) ba"
        
        self.activityIndicator.isHidden = true
        self.activityIndicator.stopAnimating()
    }
    
}
