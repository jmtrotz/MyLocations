//
//  LocationCell.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/8/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell
{
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    // Adjusts how the cell looks when it is selected and
    // rounds the corners of the thumbnail
    override func awakeFromNib()
    {
        super.awakeFromNib()
        let selection = UIView(frame: CGRect.zero)
        selection.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        selectedBackgroundView = selection
        
        photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
        photoImageView.clipsToBounds = true
        separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // Converts large image into a small thumbnail
    func thumbnail(for location: Location) -> UIImage
    {
        if location.hasPhoto, let image = location.photoImage
        {
            return image.resized(withBounds: CGSize(width: 52, height: 52))
        }
        
        return UIImage(named: "No Photo")!
    }
    
    func configure(for location: Location)
    {
        if location.locationDescription.isEmpty
        {
            descriptionLabel.text = "(No Description)"
        }
        
        else
        {
            descriptionLabel.text = location.description
        }
        
        // If a placemark exists, get the address details
        if let placemark = location.placemark
        {
            var address = ""
            
            // Append house number
            address.add(text: placemark.subThoroughfare)
            
            // Append street name
            address.add(text: placemark.thoroughfare, separatedBy: " ")
            
            // Append city name
            address.add(text: placemark.locality, separatedBy: ", ")
            
            // Set the label text
            addressLabel.text = address
        }
            
        // If the placemark doesn't exist, display the lat/long coordinates
        else
        {
            addressLabel.text = String(format: "Lat: %.8f, Long: %.8f",
                                       location.latitude, location.longitude)
        }
        
        photoImageView.image = thumbnail(for: location)
    }
}
