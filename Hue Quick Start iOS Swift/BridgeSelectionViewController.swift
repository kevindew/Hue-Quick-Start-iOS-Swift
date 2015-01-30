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
    
    // MARK: Table View Delegate
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
