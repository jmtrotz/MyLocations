//
//  MapViewController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/8/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController
{
    // Outlet where locations are shown on a map
    @IBOutlet weak var mapView: MKMapView!
    
    // Array of locations to show on the map
    var locations = [Location]()
    
    // Object representing a single object space or "scratch pad"
    // that is used to fetch, create, and save managed objects
    var managedObjectContext: NSManagedObjectContext!
    {
        // Executes the code below when the object above is set
        didSet
        {
            // Tell notification center to add an observer for
            // NSManagedObjectContextObjectsDidChange notifications
            NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange,
                                                   object: managedObjectContext, queue: OperationQueue.main)
            {
                notification in
                
                // Update locations when the view is loaded
                if self.isViewLoaded
                {
                    self.updateLocations()
                }
            }
        }
    }
    
    // Shows the user's location on the map
    @IBAction func showUser()
    {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    // Shows all tagged locations on the map
    @IBAction func showLocations()
    {
        let regionToBeShown = region(for: locations)
        mapView.setRegion(regionToBeShown, animated: true)
    }
    
    // Sends the user to the screen where location details are displayed
    // and the details can be edited
    @objc func showLocationDetails(_ sender: UIButton)
    {
        performSegue(withIdentifier: "EditLocation", sender: sender)
    }
    
    // Called just before the UI is rendered
    override func viewDidLoad()
    {
        // Call super and fetch locations from the database
        super.viewDidLoad()
        updateLocations()
        
        // If the locations array isn't empty, show them all on the map
        if !locations.isEmpty
        {
            showLocations()
        }
    }
    
    // Prepares for transitioning back to the the location details screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Make sure the identifier is correct
        if segue.identifier == "EditLocation"
        {
            // Create controller object and pass the managed object context object
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            // Create button object and use the tag to get the corresponding location
            // from the locations array, then pass the location to the controller
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
    
    func updateLocations()
    {
        // Remvoe old annotations
        mapView.removeAnnotations(locations)
        
        // Object that describes which objects are being fetched from the database
        let fetchRequest = NSFetchRequest<Location>()
        
        // Create entity and tell the fetch request that we're looking for location entities
        let entity = Location.entity()
        fetchRequest.entity = entity
        
        // Try to fetch locations from the database then add them to the map
        locations = try! managedObjectContext.fetch(fetchRequest)
        mapView.addAnnotations(locations)
    }
    
    func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion
    {
        // Region object to be returned and displayed on the map
        let region: MKCoordinateRegion
        
        // Switch on the number of annotations in the array
        switch annotations.count
        {
            // If there are no annotations, center the map on the user's current position
            case 0:
                region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            // If there is only 1 annotation, center the map on that one annotation
            case 1:
                let annotation = annotations[annotations.count - 1]
                region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            // If there are 2 or more, calculate their reach + a little padding
            default:
                var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
                var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
                // For each annotation, get their top left/bottom right coordinate
                for annotation in annotations
                {
                    topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
                    topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
                    bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
                    bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
                }
                
                // Set the center, extra spacen and the span of the annotations
                let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
                             longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
                let extraSpace = 1.1
                let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                           longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
            
                // Creaate region
                region = MKCoordinateRegion(center: center, span: span)
        }
    
        // Return region to display in the map
        return mapView.regionThatFits(region)
    }
}

extension MapViewController: MKMapViewDelegate
{
    // Creates a custom annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        // Check whether the annotation object really IS a location object. If not,
        // return nil to signal we're not making annotations for other objects
        guard annotation is Location else
        {
            return nil
        }
        
        // Ask the map to reuse an annotation view object.
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        //If an annotation view cannot be recycled, create a new one
        if annotationView == nil
        {
            // Create object and set properties to configure the look
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.isEnabled = true
            pinView.canShowCallout = true
            pinView.animatesDrop = false
            pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            pinView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            
            // Create button, place it inside the pins, and assign the pin to the annotation view
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.addTarget(self, action: #selector(showLocationDetails), for: .touchUpInside)
            pinView.rightCalloutAccessoryView = rightButton
            annotationView = pinView
        }
        
        if let annotationView = annotationView
        {
            // Assign the annotation to a view and obtain reference
            // to the button created above.
            annotationView.annotation = annotation
            let button = annotationView.rightCalloutAccessoryView as! UIButton
            
            // Set the button's tag to the index of the object in the locations array
            // so it can be found later when the button is pressed
            if let index = locations.index(of: annotation as! Location)
            {
                button.tag = index
            }
        }
        
        // Return the annotation view object
        return annotationView
    }
}
