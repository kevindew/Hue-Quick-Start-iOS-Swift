//
//  ControlLightsViewController.swift
//  Hue Quick Start iOS Swift
//
//  Ported from https://github.com/PhilipsHue/PhilipsHueSDK-iOS-OSX/blob/master/QuickStartApp_iOS/HueQuickStartApp-iOS/PHControlLightsViewController.m
//
//  Created by Kevin Dew on 22/01/2015.
//  Copyright (c) 2015 KevinDew. All rights reserved.
//

import UIKit

class ControlLightsViewController: UIViewController {
    
  let maxHue = 65535
  
  @IBOutlet var bridgeMacLabel: UILabel?
  @IBOutlet var bridgeIpLabel: UILabel?
  @IBOutlet var bridgeLastHeartbeatLabel: UILabel?
  @IBOutlet var randomLightsButton: UIButton?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let notificationManager = PHNotificationManager.defaultManager()
    // Register for the local heartbeat notifications
    notificationManager.registerObject(self, withSelector: "localConnection", forNotification: LOCAL_CONNECTION_NOTIFICATION)
    
    notificationManager.registerObject(self, withSelector: "noLocalConnection", forNotification: NO_LOCAL_CONNECTION_NOTIFICATION)
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Find Bridge", style: UIBarButtonItemStyle.Plain, target: self, action: "findNewBridgeButtonAction")
    
    navigationItem.title = "QuickStart"
    
    noLocalConnection()
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func edgesForExtendedLayout() -> UIRectEdge {
    return (UIRectEdge.Left | UIRectEdge.Bottom | UIRectEdge.Right)
  }
  
  func localConnection() {
    loadConnectedBridgeValues()
  }
  
  func noLocalConnection() {
    bridgeLastHeartbeatLabel?.text = "Not connected"
    bridgeLastHeartbeatLabel?.enabled = false
    bridgeIpLabel?.text = "Not connected"
    bridgeIpLabel?.enabled = false
    bridgeMacLabel?.text = "Not connected"
    bridgeMacLabel?.enabled = false
    
    randomLightsButton?.enabled = false
  }
  
  func loadConnectedBridgeValues() {
    let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
    
    // Check if we have connected to a bridge before
    if cache?.bridgeConfiguration?.ipaddress != nil {
      // Set the ip address of the bridge
      bridgeIpLabel?.text = cache!.bridgeConfiguration!.ipaddress

      // Set the mac adress of the bridge
      bridgeMacLabel?.text = cache!.bridgeConfiguration!.mac

      
      // Check if we are connected to the bridge right now
      let appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
      if appDelegate.phHueSdk.localConnected() {

        // Show current time as last successful heartbeat time when we are connected to a bridge
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .MediumStyle
        bridgeLastHeartbeatLabel?.text = dateFormatter.stringFromDate(NSDate())
          
        randomLightsButton?.enabled = true
      } else {
        bridgeLastHeartbeatLabel?.text = "Waiting..."
        randomLightsButton?.enabled = false
      }
    }
  }
  
  @IBAction func randomizeColoursOfConnectLights(AnyObject) {
    randomLightsButton?.enabled = false
    let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
    let bridgeSendAPI = PHBridgeSendAPI()
    
    for light in cache!.lights!.values {
      
      let lightState = PHLightState()
      
      lightState.hue = Int(arc4random()) * maxHue
      lightState.brightness = 254
      lightState.saturation = 254
      
      // Send lightstate to light
      bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState, completionHandler: { (errors: [AnyObject]!) -> () in
        
        let errorsArr = errors as? [NSError]
        
        if errorsArr != nil {
          let message = String(format: NSLocalizedString("Errors", comment: ""), arguments: errorsArr!)
          
          NSLog("Response: \(message)")
        }
        self.randomLightsButton?.enabled = true
      })
      
    }
  }
  
  func findNewBridgeButtonAction() {
    let appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
    appDelegate.searchForBridgeLocal()
  }
    
}
