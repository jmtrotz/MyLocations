//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 3/25/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController
{
    // Name of the category chosen by the user
    var selectedCategoryName = ""
    
    // Index path of the chosen category
    var selectedIndexPath = IndexPath()
    
    // Array of different category names for the user to choose from
    let categories = ["No Category",
                      "Bar",
                      "Book Store",
                      "Club",
                      "Grocery Store",
                      "Historic Building",
                      "House",
                      "Icecream Vendor",
                      "Landmark",
                      "Park"]
    
    // Called after hte UI loads
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Loops through the array of categories above
        for i in 0..<categories.count
        {
            // Compares the category name to selectedCategoryName. If they
            // match, create new IndexPath object and break out of the loop
            if categories[i] == selectedCategoryName
            {
                selectedIndexPath = IndexPath(row: i, section: 0)
                break
            }
        }
    }
    
    // Prepares for transitioning back to the previous screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Make sure the segue identifier matches the one we're looking for
        if segue.identifier == "PickedCategory"
        {
            // If it matches, set the sender
            let cell = sender as! UITableViewCell
            
            // Get the indexPath of the selected row and use it to choose
            // a category type from the array at the top of this file
            if let indexPath = tableView.indexPath(for: cell)
            {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    
    // Creates the cells shown in the table view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // Declare cell and categoryName properties
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let categoryName = categories[indexPath.row]
        
        // Set the cell label using the category names above
        cell.textLabel!.text = categoryName
        
        // If the category name matches the selected one, put a checkmark next to it
        if categoryName == selectedCategoryName
        {
            cell.accessoryType = .checkmark
        }
        
        // If not, it doesn't get a checkmark
        else
        {
            cell.accessoryType = .none
        }
        
        // Set the color of the cell when it is selected
        let selecton = UIView(frame: CGRect.zero)
        selecton.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        cell.selectedBackgroundView = selecton
        
        return cell
    }
    
    // Returns the number of cells in the table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return categories.count
    }
    
    // Called when a table cell is selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // Compares the selected cell to the one that is currently checked
        // If they don't match, add a checkmark nect to new cell and remove
        // it from the old one
        if indexPath.row != selectedIndexPath.row
        {
            if let newCell = tableView.cellForRow(at: indexPath)
            {
                newCell.accessoryType = .checkmark
            }
            
            if let oldCell = tableView.cellForRow(at: selectedIndexPath)
            {
                oldCell.accessoryType = .none
            }
            
            // Set selectedIndexPath equal to what was selected
            selectedIndexPath = indexPath
        }
    }
}
