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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "ZACSearchResultItemTableViewCell", bundle: nil), forCellReuseIdentifier: "SearchResultItemCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.isHidden = false
        
        self.mapView.isHidden = true
        
        self.barButtonItem.image = UIImage(named: "iconMapView")
        
        self.layoutUIElements()
        
        ZACNetworkManager.registerDelegate(self)
        
        ZACNetworkManager.asyncFetchMoreListings()
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
                    self.tableView.isHidden = true
                    self.mapView.isHidden = false
                    self.barButtonItem.image = UIImage(named: "iconListView")
                }
                else {
                    self.tableView.isHidden = false
                    self.mapView.isHidden = true
                    self.barButtonItem.image = UIImage(named: "iconMapView")
                }
            }
        }
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

}

extension ZACRootViewController: ZACNetworkManagerDelegate {
    func networkManager(_ networkManager: ZACNetworkManager, fetchedResults results: [ZACSearchResultItem]) {
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
        return 220
    }
    
//    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int)
//
//
//    // Variable height support
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
//
//
//    // Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
//    // If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
//    @available(iOS 7.0, *)
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat
//
//    @available(iOS 7.0, *)
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
//
//    @available(iOS 7.0, *)
//    optional public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
//
//
//    // Section header & footer information. Views are preferred over title should you decide to provide both
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? // custom view for header. will be adjusted to default or specified header height
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? // custom view for footer. will be adjusted to default or specified footer height
//
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath)
//
//
//    // Selection
//
//    // -tableView:shouldHighlightRowAtIndexPath: is called when a touch comes down on a row.
//    // Returning NO to that message halts the selection process and does not cause the currently selected row to lose its selected look while the touch is down.
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
//
//    @available(iOS 6.0, *)
//    optional public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
//
//
//    // Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
//
//    @available(iOS 3.0, *)
//    optional public func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath?
//
//    // Called after the user changes the selection.
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
//
//    @available(iOS 3.0, *)
//    optional public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
//
//
//    // Editing
//
//    // Allows customization of the editingStyle for a particular cell located at 'indexPath'. If not implemented, all editable cells will have UITableViewCellEditingStyleDelete set for them when the table has editing property set to YES.
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
//
//    @available(iOS 3.0, *)
//    optional public func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String?
//
//
//    // Use -tableView:trailingSwipeActionsConfigurationForRowAtIndexPath: instead of this method, which will be deprecated in a future release.
//    // This method supersedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil
//    @available(iOS 8.0, *)
//    optional public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
//
//
//    // Swipe actions
//    // These methods supersede -editActionsForRowAtIndexPath: if implemented
//    // return nil to get the default swipe actions
//    @available(iOS 11.0, *)
//    optional public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//
//    @available(iOS 11.0, *)
//    optional public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
//
//
//    // Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool
//
//
//    // The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath)
//
//    @available(iOS 2.0, *)
//    optional public func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?)

//    // Spring Loading
//
//    // Allows opting-out of spring loading for an particular row.
//    // If you want the interaction effect on a different subview of the spring loaded cell, modify the context.targetView property. The default is the cell.
//    // If this method is not implemented, the default is YES except when the row is part of a drag session.
//    @available(iOS 11.0, *)
//    optional public func tableView(_ tableView: UITableView, shouldSpringLoadRowAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool
}

