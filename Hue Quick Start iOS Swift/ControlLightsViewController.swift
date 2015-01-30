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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "QuickStart"

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func edgesForExtendedLayout() -> UIRectEdge {
        return (UIRectEdge.Left | UIRectEdge.Bottom | UIRectEdge.Right)
    }
    
}
