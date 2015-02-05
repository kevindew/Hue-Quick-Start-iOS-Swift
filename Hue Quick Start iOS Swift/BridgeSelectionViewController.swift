//
//  BridgeSelectionViewController.swift
//  Hue Quick Start iOS Swift
//
//  Ported from: https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/QuickStartApp_iOS/SDKWizard/PHBridgeSelectionViewController.m
//
//  Created by Kevin Dew on 29/01/2015.
//  Copyright (c) 2015 KevinDew. All rights reserved.
//

import UIKit

protocol BridgeSelectionViewControllerDelegate {
  func bridgeSelectedWithIpAddress(ipAddress: String, andMacAddress macAddress: String)
}

class BridgeSelectionViewController: UITableViewController {
  
  var bridgesFound: [String: String]?
  var delegate: BridgeSelectionViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Make it a form on iPad
    modalPresentationStyle = UIModalPresentationStyle.FormSheet
    
    // Set title of screen
    title = "Available Smart Bridges"
    
    let refreshBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh,
      target: self, action: "refreshButtonClicked")
    navigationItem.rightBarButtonItem = refreshBarButtonItem
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func refreshButtonClicked(sender: UIBarButtonItem) {
    navigationController?.dismissViewControllerAnimated(true, completion: nil)
    (UIApplication.sharedApplication().delegate as AppDelegate).searchForBridgeLocal()
  }
  
  // MARK: - Table view data source
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bridgesFound!.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
    
    // Sort bridges by mac address
    let keys = [String](bridgesFound!.keys)
    let sortedKeys = keys.sorted { $0.caseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
    
    let mac = sortedKeys[indexPath.row]
    let ip = bridgesFound![mac]
    
    cell.textLabel?.text = mac
    cell.detailTextLabel?.text = ip
    
    return cell
  }
  
  override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return "Please select a SmartBridge to use for this application"
  }
  
  // MARK: - Table View Delegate
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    // Sort bridges by mac address
    let keys = [String](bridgesFound!.keys)
    let sortedKeys = keys.sorted { $0.caseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending }
    
    // The choice of bridge to use is made, store the mac and ip address for this bridge
    
    // Get mac address and ip address of selected bridge
    let mac = sortedKeys[indexPath.row]
    let ip = bridgesFound![mac]!
    
    // Inform delegate
    delegate!.bridgeSelectedWithIpAddress(ip, andMacAddress: mac)
  }
}
