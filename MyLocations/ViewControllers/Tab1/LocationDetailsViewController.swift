//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 3/25/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

// Custom date formatter with our own special settings
private let dateFormatter: DateFormatter =
{
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController
{
    // Outlets for accessing UI elements
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    // Date formatter to make the displayed date look nice
    private let dateFormatter = DateFormatter()
    
    // Stores GPS coordinates of the placemark
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    // Placemark to extract data from
    var placemark: CLPlacemark?
    
    // Default name of the category for the placemark
    var categoryName = "No Category"
    
    // Object representing a single object space or "scratch pad"
    // that is used to fetch, create, and save managed objects
    var managedObjectContext: NSManagedObjectContext!

    // Used to get the current date
    var date = Date()
    
    // Label for the description of the location
    var descriptionText = ""
    
    // Image of the location
    var image: UIImage?
    
    // Listener for notifications
    var observer: Any!
    
    // Location object to be edited
    var locationToEdit: Location?
    {
        // If there is a location to edit, extract the values from the object
        didSet
        {
            if let location = locationToEdit
            {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }

    // Called when the done button in the nav bar is pressed
    @IBAction func done()
    {
        // Create HUD view and location objects
        let hudView = HUDView.hud(inView: view, animated: true)
        let location: Location
        
        // If we're editing a location, set HUD text accordingly and
        // assign the location object so its values can be set
        if let temp = locationToEdit
        {
            hudView.text = "Updated"
            location = temp
        }
        
        // If we're adding a new location, set HUD text accordingly and
        // assign the location object so its values can be set
        else
        {
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
        }
        
        // Set values for the location object
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        // Save the image
        if let image = image
        {
            // Get a new photo ID and assign it to the location object's photoID property,
            // but only if it didn't already have one. If a photo existed, keep the same ID
            // and overwrite the existing photo
            if !location.hasPhoto
            {
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            
            // Convert the image to JPEG format
            if let data = image.jpegData(compressionQuality: 0.5)
            {
                // Try to save the image
                do
                {
                    try data.write(to: location.photoURL, options: .atomic)
                }
                
                // Catch any errors
                catch
                {
                    print("Error writing file: \(error)")
                }
            }
        }
        
        // Try to save the location object
        do
        {
            try managedObjectContext.save()
            
            // Wait about half a second, then go back to the last screen
            afterDelay(0.6)
            {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        // Catch any errors if it doesn't save
        catch
        {
            fatalCoreDataError(error)
        }
    }
    
    // Called when the cancel button in the nav bar is pressed
    @IBAction func cancel()
    {
        navigationController?.popViewController(animated: true)
    }
    
    // Called when a location category is picked
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue)
    {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // Hides the keyboard when anywhere on the screen is tapped
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer)
    {
        // Get the touch location and the table row
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        // If the touch was anywhere in the table view except
        // the first or second section, then hide the keyboard
        if indexPath == nil && !(indexPath!.section == 0 && indexPath!.row == 0)
        {
            descriptionTextView.resignFirstResponder()
        }
    }
    
    deinit
    {
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        listenForBackgroundNotification()
        
        // If there is a location to edit, set the title accordingly
        if let location = locationToEdit
        {
            title = "Edit Location"
            
            if location.hasPhoto
            {
                if let theImage = location.photoImage
                {
                    show(image: theImage)
                }
            }
        }
        
        // Set text for various labels
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark
        {
            addressLabel.text = string(from: placemark)
        }
        
        else
        {
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = format(date: date)
        
        // Hides the keyboard when anywhere else on the screen is tapped
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    // Prepares for transitioning to the next screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Make sure the segue identifier matches the one we're looking for
        if segue.identifier == "PickCategory"
        {
            // If it matches, create controller object and set properties
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    /*
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            return 88
            
        }
            
        else if indexPath.section == 2 && indexPath.row == 2
        {
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 120, height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 16
            
            return addressLabel.frame.size.height + 20
        }
            
        else
        {
            return 44
        }
    }
    */
    
    // Limits taps to just the cells in the first two sections of the table
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        // If the cell tapped is the first or second section, then accept the tap
        if indexPath.section == 0 || indexPath.section == 1
        {
            return indexPath
        }
        
        // Else ignore the tap
        else
        {
            return nil
        }
    }
    
    // Called just before the table view cell is rendered to customize the color of the cell
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let selection = UIView(frame: CGRect.zero)
        selection.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        cell.selectedBackgroundView = selection
    }
    
    // Handles the actual taps on the table rows
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            descriptionTextView.becomeFirstResponder()
        }
        
        else if indexPath.section == 1 && indexPath.row == 0
        {
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
    }
    
    // Pulls the address from the placemark and formats it nicely
    func string(from placemark: CLPlacemark) -> String
    {
        // Stores the address lines from the placemark
        var text = ""
        
        // Append house number
        text.add(text: placemark.subThoroughfare)
        
        // Append street name
        text.add(text: placemark.thoroughfare, separatedBy: " ")
        
        // Append city name
        text.add(text: placemark.locality, separatedBy: ", ")
        
        // Append state
        text.add(text: placemark.administrativeArea, separatedBy: ", ")
        
        // Append zip code
        text.add(text: placemark.postalCode, separatedBy: " ")
        
        // Append country
        text.add(text: placemark.country, separatedBy: ", ")
        
        // Return the finished address
        return text
    }
    
    func format(date: Date) -> String
    {
        return dateFormatter.string(from: date)
    }
    
    // Listens for when the app is being sent to the background
    func listenForBackgroundNotification()
    {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main)
        {
            [weak self] _ in
            
            if let weakSelf = self
            {
                if weakSelf.presentedViewController != nil
                {
                    weakSelf.dismiss(animated: false, completion: nil)
                }
                
                weakSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    // Shows the image after it has been chosen
    func show(image: UIImage)
    {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        imageHeight.constant = 260
        tableView.reloadData()
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // Chooses an existing photo from the gallery
    func choosePhotoFromLibrary()
    {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true        
        imagePicker.view.tintColor = view.tintColor
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Takes a new photo with the camera
    func takePhotoWithCamera()
    {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Loads the chosen image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        
        if let theImage = image
        {
            show(image: theImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    // Cancels choosing an image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
    }
    
    // If the camera doesen't exist (like on a simulator), the photo
    // gallery is automatically launched instead
    func pickPhoto()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            showPhotoMenu()
        }
        
        else
        {
            choosePhotoFromLibrary()
        }
    }
    
    // Shows options to take a pic with the camera or choose an
    // existing image from the gallery
    func showPhotoMenu()
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actCancel)
        
        let actPhoto = UIAlertAction(title: "Take Photo", style: .default, handler:
        {
            _ in
            self.takePhotoWithCamera()
        })
        
        alert.addAction(actPhoto)
        
        let actLibrary = UIAlertAction(title: "Choose From Library", style: .default, handler:
        {
            _ in
            self.choosePhotoFromLibrary()
        })
        
        alert.addAction(actLibrary)
        
        present(alert, animated: true, completion: nil)
    }
}
