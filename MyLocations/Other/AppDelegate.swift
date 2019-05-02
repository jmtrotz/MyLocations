//
//  AppDelegate.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 3/20/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    // Core data stack for saving locations
    lazy var persistentContainer: NSPersistentContainer =
    {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler:
        {
            storeDescription, error in
            
            if let error = error
            {
                fatalError("Could not load data store: \(error)")
            }
        })
        
        return container
    }()
    
    // Object representing a single object space or "scratch pad"
    // that is used to fetch, create, and save managed objects
    lazy var managedObjectContext: NSManagedObjectContext = self.persistentContainer.viewContext

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        // Remove the ugly blinding white
        customizeAppearance()
        
        // Get UITabBarController
        let tabController = window!.rootViewController as! UITabBarController
        
        // Look at controllers array
        if let tabViewControllers = tabController.viewControllers
        {
            // Tab #1
            var navController = tabViewControllers[0] as! UINavigationController
            let controller = navController.viewControllers.first as! CurrentLocationViewController
            controller.managedObjectContext = managedObjectContext
            
            // Tab #2
            navController = tabViewControllers[1] as! UINavigationController
            let controller2 = navController.viewControllers.first as! LocationsViewController
            controller2.managedObjectContext = managedObjectContext
            
            // Tab #3
            navController = tabViewControllers[2] as! UINavigationController
            let controller3 = navController.viewControllers.first as! MapViewController
            controller3.managedObjectContext = managedObjectContext
            
            // Force load controller2 view right away as a workaround for core data bug that causes the app to crash
            //let _ = controller2.view
        }
        
        // Call function to listen for database errors
        listenForFatalCoreDataNotifications()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // Posts an alert if there's a database issue
    func listenForFatalCoreDataNotifications()
    {
        // Tell notification center to listen for CoreDataSaveFailedNotification
        NotificationCenter.default.addObserver(forName: CoreDataSaveFailedNotification, object: nil, queue: OperationQueue.main, using:
        {
            notifcation in
            
            // Create error message to display
            let message = """
                          There was a fatal error in the app and it cannot continue.
                          Press OK to terminate the app. Sorry for the inconvenience.
                          """
            
            // Create alert to show the message
            let alert = UIAlertController(title: "Internal Error", message: message, preferredStyle: .alert)
            
            // Create action for the alert's OK button
            let action = UIAlertAction(title: "OK", style: .default)
            {
                // Terminates the app (nicer than fatalError())
                _ in let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core Cata error", userInfo: nil)
                exception.raise()
            }
            
            // Add the action to the alert
            alert.addAction(action)
            
            // Get the current view controller and set details of alert presentation
            let tabController = self.window!.rootViewController!
            tabController.present(alert, animated: true, completion: nil)
        })
    }
    
    func customizeAppearance()
    {
        UINavigationBar.appearance().barTintColor = UIColor.black
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UITabBar.appearance().barTintColor = UIColor.black
        
        let tintColor = UIColor(red: 255/255.0, green: 238/255.0, blue: 136/255.0, alpha: 1.0)
        UITabBar.appearance().tintColor = tintColor
    }
}
