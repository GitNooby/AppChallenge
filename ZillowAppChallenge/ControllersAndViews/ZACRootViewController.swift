//
//  ViewController.swift
//  ZillowAppChallenge
//
//  Created by Kai Zou on 9/15/18.
//  Copyright © 2018 Kai Zou. All rights reserved.
//

import UIKit
import MapKit

class ZACRootViewController: UIViewController {

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var barButtonItem: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var mapViewAnnotations: [String: ZACListingAnnotation] = [:]
    
    private let regionRadius: CLLocationDistance = 2000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ZACSearchResultItemTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchResultItemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isHidden = false
        
        self.mapView.register(ZACListingAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        self.mapView.mapType = .mutedStandard
        self.mapView.isHidden = true
        self.mapView.delegate = self
        
        self.barButtonItem.image = UIImage(named: "iconMapView")?.withRenderingMode(.alwaysOriginal)
        
        self.layoutUIElements()
        
        ZACNetworkManager.registerDelegate(self)
        
        ZACNetworkManager.asyncFetchMoreListings()
        ZACImageCacher.clearCache()
    }
    
    func moveMapToLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius*2.0, regionRadius*2)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layoutUIElements()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction private func buttonPressed(_ sender: Any) {
        if let sender = sender as? UIBarButtonItem {
            if sender == self.barButtonItem {
                if (self.tableView.isHidden == false && self.mapView.isHidden == true) {
                    self.animateMapViewToFront()
                }
                else {
                    self.animateTableViewToFront()
                }
            }
        }
    }
    
    private func animateTableViewToFront() {
        UIView.animate(withDuration: 0.8, delay: 0, options: [], animations: {
            self.tableView.alpha = 1
            self.mapView.alpha = 0
        }, completion: { _ in
            self.tableView.isHidden = false
            self.mapView.isHidden = true
        })
        self.barButtonItem.image = UIImage(named: "iconMapView")?.withRenderingMode(.alwaysOriginal)
    }
    
    private func animateMapViewToFront() {
        UIView.animate(withDuration: 0.8, delay: 0, options: [], animations: {
            self.tableView.alpha = 0
            self.mapView.alpha = 1
        }, completion: { _ in
            self.tableView.isHidden = true
            self.mapView.isHidden = false
        })
        self.barButtonItem.image = UIImage(named: "iconListView")?.withRenderingMode(.alwaysOriginal)
    }
    
    private func layoutUIElements() {
        // layout toolBar
        self.toolBar.translatesAutoresizingMaskIntoConstraints = false
        self.toolBar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.toolBar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.toolBar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        self.toolBar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        
        // layout tableView
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.toolBar.topAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        
        // layout mapView
        self.mapView.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.mapView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.mapView.bottomAnchor.constraint(equalTo: self.toolBar.topAnchor).isActive = true
        self.mapView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    private func addListingsToMapView(_ listings: [ZACSearchResultItem]) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        if listings.count == 0 {
            return
        }
        
        var totalLat: Double = 0;
        var totalLon: Double = 0;
        
        for listing: ZACSearchResultItem in listings {
            let title = "\(listing.streetNumber ?? "--") \(listing.streetName ?? "--")"
            let subtitle: String
            if let price = listing.price {
                subtitle = "$\(price)"
            } else {
                subtitle = "--"
            }
            
            totalLat += listing.latitude!
            totalLon += listing.longitude!
            
            let location = CLLocation(latitude: listing.latitude!, longitude: listing.longitude!)
            let listingAnnotation = ZACListingAnnotation(title: title, subtitle: subtitle, coordinate: location.coordinate)
            self.mapView.addAnnotation(listingAnnotation)
            self.mapViewAnnotations[listing.id!] = listingAnnotation
        }
        
        let centerLat = totalLat / Double(listings.count)
        let centerLon = totalLon /  Double(listings.count)
        let mapCenter = CLLocation(latitude: centerLat, longitude: centerLon)
        self.moveMapCenter(mapCenter.coordinate)
        
    }
    
    private func moveMapCenter(_ mapCenter: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMakeWithDistance(mapCenter, 2000*2, 2000*2)
        mapView.setRegion(region, animated: true)
    }

}

extension ZACRootViewController: ZACNetworkManagerDelegate {
    func networkManager(_ networkManager: ZACNetworkManager, fetchedResults results: [ZACSearchResultItem]) {
        self.addListingsToMapView(networkManager.searchResultItemsArray!)
        self.tableView.reloadData()
    }
}

extension ZACRootViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ZACNetworkManager.fetchedListings().count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ZACSearchResultItemTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SearchResultItemCell", for: indexPath) as! ZACSearchResultItemTableViewCell
        
        cell.unpopulate()
        let searchResultItem: [ZACSearchResultItem] = ZACNetworkManager.fetchedListings()
        cell.populate(with: searchResultItem[indexPath.row])
        
        return cell
    }
    
}

extension ZACRootViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220  // TODO: probably shouldn't hard code
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let listings = ZACNetworkManager.fetchedListings()
        let selectedListing = listings[indexPath.row]
        let location = CLLocation(latitude: selectedListing.latitude!, longitude: selectedListing.longitude!)
        self.moveMapCenter(location.coordinate)
        self.animateMapViewToFront()
        
        let listingAnnotation = self.mapViewAnnotations[selectedListing.id!]
        self.mapView.selectAnnotation(listingAnnotation!, animated: true)
    }
//    optional public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
}

extension ZACRootViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is ZACListingAnnotation {
            let listingAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)
            if listingAnnotationView is ZACListingAnnotationView {
                return listingAnnotationView
            }
        }

        return nil;
    }
    
}
