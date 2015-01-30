//
//  AppDelegate.swift
//  Hue Quick Start iOS Swift
//  
//  Ported from: https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/QuickStartApp_iOS/HueQuickStartApp-iOS/PHAppDelegate.m
//
//  Created by Kevin Dew on 22/01/2015.
//  Copyright (c) 2015 KevinDew. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BridgeSelectionViewControllerDelegate {

    // Create sdk instance
    let phHueSdk:PHHueSDK = PHHueSDK()
    var window: UIWindow?
    var navigationController: UINavigationController?
    var noConnectionAlert: UIAlertController?
    var noBridgeFoundAlert: UIAlertController?
    var authenticationFailedAlert: UIAlertView?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        phHueSdk.startUpSDK()
        phHueSdk.enableLogging(true)
        let notificationManager = PHNotificationManager.defaultManager()
        
        navigationController = window!.rootViewController as? UINavigationController
        
        // The SDK will send the following notifications in response to events:
        //
        // - LOCAL_CONNECTION_NOTIFICATION
        // This notification will notify that the bridge heartbeat occurred and the bridge resources cache data has been updated
        //
        // - NO_LOCAL_CONNECTION_NOTIFICATION
        // This notification will notify that there is no connection with the bridge
        //
        // - NO_LOCAL_AUTHENTICATION_NOTIFICATION
        // This notification will notify that there is no authentication against the bridge
        notificationManager.registerObject(self, withSelector: "localConnection" , forNotification: LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: "noLocalConnection", forNotification: NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector: "notAuthenticated", forNotification: NO_LOCAL_AUTHENTICATION_NOTIFICATION)
        
        // The local heartbeat is a regular timer event in the SDK. Once enabled the SDK regular collects the current state of resources managed by the bridge into the Bridge Resources Cache
        enableLocalHeartbeat()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // Stop heartbeat
        disableLocalHeartbeat()
        
        // Remove any open popups
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        noBridgeFoundAlert?.dismissViewControllerAnimated(false, completion: nil)
        noBridgeFoundAlert = nil
        authenticationFailedAlert?.dismissWithClickedButtonIndex(authenticationFailedAlert!.cancelButtonIndex, animated: false)
        authenticationFailedAlert = nil
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        enableLocalHeartbeat()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    // MARK: HueSDK
    
    /// Notification receiver for successful local connection
    func localConnection() {
        checkConnectionState()
    }
    
    
    /// Notification receiver for failed local connection
    func noLocalConnection() {
        checkConnectionState()
    }
    
    ///  Notification receiver for failed local authentication
    func notAuthenticated() {
        // We are not authenticated so we start the authentication process
        
        // Move to main screen (as you can't control lights when not connected)
        navigationController!.popToRootViewControllerAnimated(false)
        
        // Dismiss modal views when connection is lost
        if navigationController!.presentedViewController != nil {
            navigationController!.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Remove no connection alert
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        
        // Start local authenticion process
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.doAuthentication()
        }
    }
    
    /// Checks if we are currently connected to the bridge locally and if not, it will show an error when the error is not already shown.
    func checkConnectionState() {
        if !phHueSdk.localConnected() {
            // Dismiss modal views when connection is lost
            
            if navigationController!.presentedViewController != nil {
                navigationController!.dismissViewControllerAnimated(true, completion: nil)
            }
            
            // No connection at all, show connection popup
            
            if noConnectionAlert == nil {
                navigationController!.popToRootViewControllerAnimated(true)
                
                // Showing popup, so remove this view
                removeLoadingView()
                showNoConnectionDialog()
            }
        } else {
            // One of the connections is made, remove popups and loading views
            noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
            noConnectionAlert = nil
            removeLoadingView()
        }
    }
    
    /// Shows the first no connection alert with more connection options
    func showNoConnectionDialog() {
        noConnectionAlert = UIAlertController(
            title: NSLocalizedString("No Connection", comment: "No connection alert title"),
            message: NSLocalizedString("Connection to bridge is lost", comment: "No Connection alert message"),
            preferredStyle: .Alert
        )
        
        let reconnectAction = UIAlertAction(
            title: NSLocalizedString("Reconnect", comment: "No connection alert reconnect button"),
            style: .Default
        ) { (_) in
            // Retry, just wait for the heartbeat to finish
            self.showLoadingViewWithText(NSLocalizedString("Connecting...", comment: "Connecting text"))
        }
        noConnectionAlert!.addAction(reconnectAction)
        
        let newBridgeAction = UIAlertAction(
            title: NSLocalizedString("Find new bridge", comment: "No connection find new bridge button"),
            style: .Default
        ) { (_) in
            self.searchForBridgeLocal()
        }
        noConnectionAlert!.addAction(newBridgeAction)
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
            style: .Cancel
        ) { (_) in
            self.disableLocalHeartbeat()
        }
        noConnectionAlert!.addAction(cancelAction)
        window!.rootViewController!.presentViewController(noConnectionAlert!, animated: true, completion: nil)
    }
    
    // MARK: Heartbeat control
    
    /// Starts the local heartbeat with a 10 second interval
    func enableLocalHeartbeat() {
        // The heartbeat processing collects data from the bridge so now try to see if we have a bridge already connected
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        if cache?.bridgeConfiguration?.ipaddress != nil {
            showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
            phHueSdk.enableLocalConnection()
        } else {
            searchForBridgeLocal()
        }
    }
    
    /// Stops the local heartbeat
    func disableLocalHeartbeat() {
        phHueSdk.disableLocalConnection()
    }
    
    // MARK: Bridge searching and selection
    
    /// Search for bridges using UPnP and portal discovery, shows results to user or gives error when none found.
    func searchForBridgeLocal() {
        // Stop heartbeats
        disableLocalHeartbeat()
        
        // Show search screen
        showLoadingViewWithText(NSLocalizedString("Searching", comment: "Searching for bridges text"))
        
        // A bridge search is started using UPnP to find local bridges
        
        // Start search
        let bridgeSearch = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAdressSearch: true)
        bridgeSearch.startSearchWithCompletionHandler { (bridgesFound: [NSObject: AnyObject]!) -> () in
            // Done with search, remove loading view
            self.removeLoadingView()
            
            // The search is complete, check whether we found a bridge
            if bridgesFound.count > 0 {
                // Results were found, show options to user (from a user point of view, you should select automatically when there is only one bridge found)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let bridgeViewController = storyboard.instantiateViewControllerWithIdentifier("BridgeSelection") as BridgeSelectionViewController
                bridgeViewController.bridgesFound = (bridgesFound as [String: String])
                bridgeViewController.delegate = self
                let navController = UINavigationController(rootViewController: bridgeViewController)
                self.navigationController!.presentViewController(navController, animated: true, completion: nil)

            } else {
                // No bridge was found was found. Tell the user and offer to retry..
                
                self.noBridgeFoundAlert = UIAlertController(
                    title: NSLocalizedString("No bridges", comment: "No bridge found alert title"),
                    message: NSLocalizedString("Could not find bridge", comment: "No bridge found alert message"),
                    preferredStyle: .Alert
                )
                
                let retryAction = UIAlertAction(
                    title: NSLocalizedString("Rertry", comment: "No bridge found alert retry button"),
                    style: .Default
                ) { (_) in
                    self.searchForBridgeLocal()
                }
                self.noBridgeFoundAlert!.addAction(retryAction)
                let cancelAction = UIAlertAction(
                    title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
                    style: .Cancel
                ) { (_) in
                    self.disableLocalHeartbeat()
                }
                self.noBridgeFoundAlert!.addAction(cancelAction)
                self.window!.rootViewController!.presentViewController(self.noBridgeFoundAlert!, animated: true, completion: nil)
            }
        }
    }
    
    /// Delegate method for BridgeSelectionViewController which is invoked when a bridge is selected
    func bridgeSelectedWithIpAddress(ipAddress:String, andMacAddress macAddress:String) {
        // Removing the selection view controller takes us to the 'normal' UI view
        window!.rootViewController! .dismissViewControllerAnimated(true, completion: nil)
        
        // Show a connecting view while we try to connect to the bridge
        showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
        
        // Set the username, ipaddress and mac address, as the bridge properties that the SDK framework will use
        phHueSdk.setBridgeToUseWithIpAddress(ipAddress, macAddress: macAddress)
        
        // Setting the hearbeat running will cause the SDK to regularly update the cache with the status of the bridge resources
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.enableLocalHeartbeat()
        }
    }
    
    // MARK: Bridge authentication
    
    /// Start the local authentication process
    func doAuthentication() {
        disableLocalHeartbeat()
        
        // To be certain that we own this bridge we must manually push link it. Here we display the view to do this.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let pushLinkViewController = storyboard.instantiateViewControllerWithIdentifier("BridgePushLink") as BridgePushLinkViewController
        
        navigationController?.presentViewController(
            pushLinkViewController,
            animated: true,
            completion: {(bool) in
                pushLinkViewController.startPushLinking()
        })
    }
    
    // Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was successfull
    func pushlinkSuccess() {
    }
    
    // Delegate method for PHBridgePushLinkViewController which is invoked if the pushlinking was not successfull
    func pushlinkFailed(error: PHError) {
    }
    
    // MARK: - Loading view
    
    // Shows an overlay over the whole screen with a black box with spinner and loading text in the middle
    func showLoadingViewWithText(text:String) {
    }
    
    // Removes the full screen loading overlay.
    func removeLoadingView() {
    }
}

