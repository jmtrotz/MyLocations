//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 3/20/19.
//  Class: CS 330
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate
{
    // Outlets for labels & buttons in the UI
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // Location manager for getting GPS coordinates
    let locationManager = CLLocationManager()
    
    // Stores the user's current location
    var location: CLLocation?
    
    // Keeps track if location is currently being updated or not
    var updatingLocation = false
    
    // Stores any location errors
    var lastLocationError: Error?
    
    // Geocoder to turn location coordinates into an address
    var geocoder = CLGeocoder()
    
    // Placemark data for a geographic location
    var placemark: CLPlacemark?
    
    // Keeps track if any geocoding is currently underway or not
    var performingReverseGeocoding = false
    
    // Stores any geocoding errors
    var lastGeocodingError: Error?
    
    // Timer to track how long it takes to get a location fix
    var timer: Timer?
    
    // Object representing a single object space or "scratch pad"
    // that is used to fetch, create, and save managed objects
    var managedObjectContext: NSManagedObjectContext!
    
    // System sound object
    var soundID: SystemSoundID = 0
    
    // Keeps track if the logo button is visible or not
    var logoVisible = false
    
    // Logo/button that hides the labels until tapped
    lazy var logoButton: UIButton =
    {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
        button.center.x = self.view.bounds.midX
        button.center.y = 220
        return button
    }()
    
    // Gets the user's location
    @IBAction func getLocation()
    {
        // Check if location permission has been granted
        let authStatus = CLLocationManager.authorizationStatus()
        
        // Request permission
        if authStatus == .notDetermined
        {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // Show alert if permission is denied
        if authStatus == .denied || authStatus == .restricted
        {
            showLocationServicesDeniedAlert()
            return
        }
        
        // Hide the logo
        if logoVisible
        {
            hideLogoView()
        }
        
        // If location is being updated, then stop location manager
        if updatingLocation
        {
            stopLocationManager()
        }
        
        // Else reset properties and call the function to start the location manager
        else
        {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocaionManager()
        }
        
        // Update labels in the UI
        updateLabels()
    }
    
    // Function called by the timer after 60 seconds to stop
    // the location manager
    @objc func didTimeOut()
    {
        // If no location has been found, stop
        // the location manager and log an error
        if location == nil
        {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain",
                                        code: 1, userInfo: nil)
        }
    }
    
    // Called before the UI loads
    override func viewWillAppear(_ animated: Bool)
    {
        // Call super, then hide the navigation bar
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    // Called just before the UI is dismissed
    override func viewWillDisappear(_ animated: Bool)
    {
        // Undo what we did in the function above
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    // Called when the UI loads
    override func viewDidLoad()
    {
        // Call super, play a sound, and get location data
        super.viewDidLoad()
        loadSoundEffect("Sound.caf")
        updateLabels()
    }
    
    // Prepares for transitioning to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Make sure the segue identifier matches the one we're looking for
        if segue.identifier == "TagLocation"
        {
            // If it matches, create controller object and set properties
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    // Pulls address from the placemark and formats it nicely
    func string(from placemark: CLPlacemark) -> String
    {
        // Stores the address lines from the placemark
        var line1 = ""
        var line2 = ""
        
        // Append house number
        line1.add(text: placemark.subThoroughfare)
        
        // Append street name
        line1.add(text: placemark.thoroughfare, separatedBy: " ")
        
        // Append city name
        line2.add(text: placemark.locality)
        
        // Append state
        line2.add(text: placemark.administrativeArea, separatedBy: " ")
        
        // Append zip code
        line2.add(text: placemark.postalCode, separatedBy: " ")
        
        // Combine the 2 lines together and return them
        line1.add(text: line2, separatedBy: "\n")
        return line1
    }
    
    // Prints an error message if there's an issue getting location data
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("didFailWithError \(error.localizedDescription)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue
        {
            return
        }
        
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    // Shows the logo that hides the labels
    func showLogoView()
    {
        if !logoVisible
        {
            logoVisible = true
            containerView.isHidden = true
            view.addSubview(logoButton)
        }
    }
    
    // Hides the logo that hides the labels
    func hideLogoView()
    {
        if !logoVisible
        {
            return
        }
        
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        // Moves the container view to the right
        let centerX = view.bounds.midX
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover, forKey: "panelMover")
        
        // Slides the logo image off of the screen
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover, forKey: "logoMover")
        
        // Rotates the logo as it is being slid away
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator, forKey: "logoRotator")
    }
    
    // Removes animations from the container view and logo after
    // animations have finished
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool)
    {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }
    
    // Udates location data
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // Get the user's location
        let newLocation = locations.last!
        
        // Stores distance between the new and old locaton readings
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        
        // If the location value is too old (i.e. older than 5 seconds),
        // then it is a cached value, so we don't want it
        if newLocation.timestamp.timeIntervalSinceNow < -5
        {
            return
        }
        
        // If accuracy is less than 0, then the results are invalid
        if newLocation.horizontalAccuracy < 0
        {
            return
        }
        
        // Calculate the distance between new and old location readings
        if let location = location
        {
            distance = newLocation.distance(from: location)
        }
        
        // If location is null or the accuracy of the new location data is better
        // than the accuracy of the old location data, then we're happy
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy
        {
            // Store the new location data and remove any stored errors
            location = newLocation
            lastLocationError = nil
            
            // If the accuracy of the new location is equal to or better than
            // the desired accuracy, then we're done with the location manager
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy
            {
                stopLocationManager()
                
                // Force reverse geocoding for the final location reading, even
                // if it's already performing another geocoding request
                if distance > 0
                {
                    performingReverseGeocoding = false
                }
            }
            
            // Update the UI
            updateLabels()
            
            // Make sure reverse geocoding isn't being done
            if !performingReverseGeocoding
            {
                // If not, set the property to true
                performingReverseGeocoding = true
                
                // Start reverse geocoding
                geocoder.reverseGeocodeLocation(newLocation, completionHandler:
                {
                    placemarks, error in
                    
                    self.lastGeocodingError = error
                    
                    // If there's mo errors and the unwrapped placemarks array
                    // is not empty, store the placemark
                    if error == nil, let place = placemarks, !place.isEmpty
                    {
                        // If it's the first time, play a sound effect
                        if self.placemark == nil
                        {
                            self.playSoundEffect()
                        }
                        
                        self.placemark = place.last!
                    }
                    
                    // If not, set placemark to null
                    else
                    {
                        self.placemark = nil
                    }
                    
                    // Set the property back to false and update UI labels
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
            
            // If the coordinates are not significantly different from the previous
            // ones and it's been more than 10 seconds, then it's time to give up
            else if distance < 1
            {
                let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
                
                if timeInterval > 10
                {
                    stopLocationManager()
                    updateLabels()
                }
            }
        }
    }
    
    // Starts the location manager
    func startLocaionManager()
    {
        // Check if location is enabled
        if CLLocationManager.locationServicesEnabled()
        {
            // If so, start the location manager and get the user's locaton
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            // Start timer and have it call didTimeOut() after 60 seconds
            timer = Timer.scheduledTimer(timeInterval: 60, target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil, repeats: false)
        }
    }
    
    // Stops the location manager in the event of an error
    func stopLocationManager()
    {
        if updatingLocation
        {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            
            // Cancel timer in the event stopLocationManager()
            // is called before the timer stops
            if let timer = timer
            {
                timer.invalidate()
            }
        }
    }
    
    // Shows an alert if location is off or permission is denied
    func showLocationServicesDeniedAlert()
    {
        // Create the alert and action, then add the action to the alert
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message: "Please enable location services for this app in Settings",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        
        // Show the alert
        present(alert, animated: true, completion: nil)
    }
    
    // Updates labels in the UI
    func updateLabels()
    {
        // If location has been successfully received, update labels
        if let location = location
        {
            // Formats coordinates to only have 8 digits behind the decimal point
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
            messageLabel.text = ""
            
            // Show the address if one was found for the placemark
            if let placemark = placemark
            {
                addressLabel.text = string(from: placemark)
            }
            
            // Shown if reverse geocoding is still underway
            else if performingReverseGeocoding
            {
                addressLabel.text = "Searching for Address..."
            }
            
            // Shown if there was an error while reverse geocoding
            else if lastGeocodingError != nil
            {
                addressLabel.text = "Error Finding Address"
            }
            
            // Shown if no address was found for the location
            else
            {
                addressLabel.text = "No Address Found"
            }
        }
        
        // If not, show them a message stating what's wrong
        else
        {
            // Make labels blank and hide the tag button
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
            
            // Stores the message to be shown
            let statusMessage: String
            
            // Decide what message to show the user
            if let error = lastLocationError as NSError?
            {
                // Error shown if location is disabled
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue
                {
                    statusMessage = "Location Services Disabled"
                }
                
                // Error shown if getting location fails for
                // one of many possible reasons
                else
                {
                    statusMessage = "Error Getting Location"
                }
            }
            
            // Error to be shown if location services are disabled
            else if !CLLocationManager.locationServicesEnabled()
            {
                statusMessage = "Location Services Disabled"
            }
            
            // Message shown when the location is beting updated
            else if updatingLocation
            {
                statusMessage = "Searching..."
            }
            
            // Message shown if it's the first time the app is being run
            else
            {
                statusMessage = ""
                showLogoView()
            }
            
            // Display the message and call the function to
            // set the text for the get location button
            messageLabel.text = statusMessage
            configureGetButton()
        }
    }
    
    // Changes the text shown in the get location button
    func configureGetButton()
    {
        let spinnerTag = 1000
        
        // Show "stop" if location is being updated
        if updatingLocation
        {
            getButton.setTitle("Stop", for: .normal)
            
            // Adds a spinner under the message label
            if view.viewWithTag(spinnerTag) == nil
            {
                let spinner = UIActivityIndicatorView(style: .white)
                spinner.center = messageLabel.center
                spinner.center.y += (spinner.bounds.size.height / 2) + 25
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        }
        
        // Set default title if location is not being updated
        else
        {
            getButton.setTitle("Get My Location", for: .normal)
            
            // Remove the spinner
            if let spinner = view.viewWithTag(spinnerTag)
            {
                spinner.removeFromSuperview()
            }
        }
    }
    
    // Loads the sound file and puts it into a new sound object
    func loadSoundEffect(_ name: String)
    {
        if let path = Bundle.main.path(forResource: name, ofType: nil)
        {
            let fileURL = URL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
            
            if error != kAudioServicesNoError
            {
                print("Error code \(error) loading sound: \(path)")
            }
        }
    }
    
    // Disposes the sound object
    func unloadSoundEffect()
    {
        AudioServicesDisposeSystemSoundID(soundID)
    }
    
    // Plays a sound effect
    func playSoundEffect()
    {
        AudioServicesPlaySystemSound(soundID)
    }
}
