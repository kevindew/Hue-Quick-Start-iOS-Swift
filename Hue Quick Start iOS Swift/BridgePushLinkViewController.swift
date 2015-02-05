//
//  BridgePushLinkViewController.swift
//  Hue Quick Start iOS Swift
// 
//  Ported from: https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/QuickStartApp_iOS/SDKWizard/PHBridgePushLinkViewController.m
//
//  Created by Kevin Dew on 29/01/2015.
//  Copyright (c) 2015 KevinDew. All rights reserved.
//

import UIKit

protocol BridgePushLinkViewControllerDelegate {
  func pushlinkSuccess()
  func pushlinkFailed(error: PHError)
}

class BridgePushLinkViewController: UIViewController {
  
  @IBOutlet var progressView: UIProgressView!
  var phHueSdk: PHHueSDK!
  var delegate: BridgePushLinkViewControllerDelegate!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Make it a form on iPad
    modalPresentationStyle = UIModalPresentationStyle.FormSheet
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /// Starts the pushlinking process
  func startPushLinking() {
    
    // Set up the notifications for push linkng
    let notificationManager = PHNotificationManager.defaultManager()
    
    notificationManager.registerObject(self, withSelector: "authenticationSuccess", forNotification: PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION)
    
    notificationManager.registerObject(self, withSelector: "authenticationFailed", forNotification: PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION)
    
    notificationManager.registerObject(self, withSelector: "noLocalConnection", forNotification: PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION)
    
    notificationManager.registerObject(self, withSelector: "noLocalBridge", forNotification: PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION)
    
    notificationManager.registerObject(self, withSelector: "buttonNotPressed:", forNotification: PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION)
    
    // Call to the hue SDK to start pushlinking process
    phHueSdk.startPushlinkAuthentication()
  }
  
  /// Notification receiver which is called when the pushlinking was successful
  func authenticationSuccess() {
    // The notification PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION was received. We have confirmed the bridge.
    
    // De-register for notifications and call pushLinkSuccess on the delegate
    PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    
    // Inform delegate
    delegate.pushlinkSuccess()
  }
  
  /// Notification receiver which is called when the pushlinking failed because the time limit was reached
  func authenticationFailed() {
    // De-register for notifications and call pushLinkSuccess on the delegate
    PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    
    let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_TIME_LIMIT_REACHED.value), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: time limit reached."])
    
    // Inform Delegate
    delegate.pushlinkFailed(error)
  }
  
  /// Notification receiver which is called when the pushlinking failed because the local connection to the bridge was lost
  func noLocalConnection() {
    // Deregister for all notifications
    PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    
    let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_NO_CONNECTION.value), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: No local connection to bridge."])
    
    // Inform Delegate
    delegate.pushlinkFailed(error)
  }
  
  /// Notification receiver which is called when the pushlinking failed because we do not know the address of the local bridge
  func noLocalBridge() {
    // Deregister for all notifications
    PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    
    let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_NO_LOCAL_BRIDGE.value), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: No local bridge found."])
    
    // Inform Delegate
    delegate.pushlinkFailed(error)
  }
  
  /// This method is called when the pushlinking is still ongoing but no button was pressed yet.
  /// :param: notification The notification which contains the pushlinking percentage which has passed.
  func buttonNotPressed(notification: NSNotification) {
    // Update status bar with percentage from notification
    let dict = notification.userInfo!
    let progressPercentage = dict["progressPercentage"] as Int!
    
    // Convert percentage to the progressbar scale
    let progressBarValue = Float(progressPercentage) / 100.0
    progressView.progress = progressBarValue
  }
}
