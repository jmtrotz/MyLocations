//
//  Functions.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/2/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import Foundation

// Notification posted if saving a location fails
let CoreDataSaveFailedNotification = Notification.Name(rawValue: "CoreDataSaveFailedNotification")

// Gets path to the app's documents directory
let applicationDocumentsDirectory: URL =
{
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}()

// Posts notificaion if saving a location to the database fails
func fatalCoreDataError(_ error: Error)
{
    NotificationCenter.default.post(name: CoreDataSaveFailedNotification, object: nil)
}

// Waits for the given delay, then runs the closure that it was passed
func afterDelay(_ seconds: Double, run: @escaping () -> Void)
{
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}
