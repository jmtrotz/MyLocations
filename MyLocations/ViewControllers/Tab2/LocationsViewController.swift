//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/8/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController
{
    // Object representing a single object space or "scratch pad"
    // that is used to fetch, create, and save managed objects
    var managedObjectContext: NSManagedObjectContext!
    
    lazy var fetchedResultsController: NSFetchedResultsController<Location> =
    {
        // Object that describes which objects are being fetched from the database
        let fetchRequest = NSFetchRequest<Location>()
        
        // Create entity and tell the fetch request that we're looking for location entities
        let entity = Location.entity()
        fetchRequest.entity = entity
        
        // Tell the fetch request to sort results by the 'category' and 'date'
        // attributes and to fetch 20 results at a time
        let sort = NSSortDescriptor(key: "category", ascending: true)
        let sort2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sort, sort2]
        fetchRequest.fetchBatchSize = 20
        
        // Create fetched results controller and set attributes
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")
        
        // Set fetched results controller delegate and return the object
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    // Called when the view controller is destroyed
    // Removes the fetched results controller delegate
    deinit
    {
        fetchedResultsController.delegate = nil
    }
    
    // Called when the UI loads
    override func viewDidLoad()
    {
        // Call super, add an edit button to the nav bar, and fetch data from the database
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
        // Delete cache for fetched results controller as a workaround for a core data bug
        //NSFetchedResultsController<Location>.deleteCache(withName: "Location")
        performFetch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "EditLocation"
        {
            let controller = segue.destination as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            {
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
            }
        }
    }
    
    // Deletes a location from the database
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        // Confirm editing style is infact 'delete'
        if editingStyle == .delete
        {
            // Get location object and tell managed object context to delete it
            let location = fetchedResultsController.object(at: indexPath)
            location.removePhotoFile()
            managedObjectContext.delete(location)
            
            // Try to save changes
            do
            {
                try managedObjectContext.save()
            }
                
                // Catch any errors
            catch
            {
                fatalCoreDataError(error)
            }
        }
    }
    
    // Creates a custom table view section
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        // Create custom label for the section
        let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14)
        let label = UILabel(frame: labelRect)
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section)
        label.textColor = UIColor(white: 1.0, alpha: 0.6)
        label.backgroundColor = UIColor.clear
        
        // Create a custom separator for the section
        let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5, width: tableView.bounds.size.width - 15, height: 0.5)
        let separator = UIView(frame: separatorRect)
        separator.backgroundColor = tableView.separatorColor
        
        // Add the above custom pieces into the section view and return it
        let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight)
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor(white: 0, alpha: 0.85)
        view.addSubview(label)
        view.addSubview(separator)
        return view
    }
    
    // Returns a cell to be inserted into the table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // Create cell and location objects
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        let location = fetchedResultsController.object(at: indexPath)
        
        // Configure the table cell for data from the
        // location object and return the cell
        cell.configure(for: location)        
        return cell
    }
    
    // Returns the title of the table section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name.uppercased()
    }
    
    // Returns the number of rows in a table section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    // Returns the number of sections in the table
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return fetchedResultsController.sections!.count
    }
    
    // Fetches data from the database
    func performFetch()
    {
        // Try to perform a database query
        do
        {
            try fetchedResultsController.performFetch()
        }
        
        // Catch any errors
        catch
        {
            fatalCoreDataError(error)
        }
    }
}

// NSFetchedResultsController Delegate Extension
extension LocationsViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        print("*** controllerWillChangeContent")
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        switch type
        {
            case .insert:
                print("*** NSFetchedResultsChangeInsert (object)")
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            
            case .delete:
                print("*** NSFetchedResultsChangeDelete (object)")
                tableView.deleteRows(at: [indexPath!], with: .fade)
            
            case .update:
                print("*** NSFetchedResultsChangeUpdate (object)")
                
                if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell
                {
                    let location = controller.object(at: indexPath!) as! Location
                    cell.configure(for: location)
                }
            
            case .move:
                print("*** NSFetchedResultsChangeMove (object)")
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo:
        NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        switch type
        {
            case .insert:
                print("*** NSFetchedResultsChangeInsert (section)")
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            
            case .delete:
                print("*** NSFetchedResultsChangeDelete (section)")
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            
            case .update:
                print("*** NSFetchedResultsChangeUpdate (section)")
            
            case .move:
                print("*** NSFetchedResultsChangeMove (section)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
    }
}
