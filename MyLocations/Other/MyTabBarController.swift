//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/17/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController
{
    // Change the status bar text color to white
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
    
    // By returning nil, the tab bar controller will look at its own
    // preferredStatusBarStyle property instead of those from the
    // other view controllers
    override var childForStatusBarStyle: UIViewController?
    {
        return nil
    }
}
