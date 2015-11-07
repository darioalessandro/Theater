//
//  AppDelegate.swift
//  RemoteCam
//
//  Created by Dario Lencina on 10/31/15.
//  Copyright © 2015 dario. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        InAppPurchasesManager.sharedManager().reloadProductsWithHandler { (i, e) in }
        application.statusBarStyle = .LightContent
        self.setCustomNavBarTheme()
        return true
    }
    
    func setCustomNavBarTheme() {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.blackColor()
        shadow.shadowOffset = CGSizeMake(0.0, 1.0)
        
        let app = UINavigationBar.appearance()

        app.setBackgroundImage(UIImage(named:"blueBar"), forBarMetrics: .Default)
        let atts = [
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSShadowAttributeName : shadow
        ]

        app.titleTextAttributes = atts
        
        let buttonApp = UIBarButtonItem.appearance()
        buttonApp.setTitleTextAttributes(atts, forState: .Normal)
        buttonApp.setBackgroundImage(UIImage(named:"navigationBarButton"), forState: .Normal, barMetrics: .Default)
        
        
        let backButtonPressed = UIImage(named:"navigationBarBack")
        let _backButtonPressed = backButtonPressed!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 14, 0, 4))
        
        buttonApp.setBackButtonBackgroundImage(_backButtonPressed, forState: .Normal, barMetrics: .Default)
        
    }


    func applicationWillResignActive(application: UIApplication) {}

    func applicationDidEnterBackground(application: UIApplication) {}

    func applicationWillEnterForeground(application: UIApplication) {}

    func applicationDidBecomeActive(application: UIApplication) {}

    func applicationWillTerminate(application: UIApplication) {}

}

