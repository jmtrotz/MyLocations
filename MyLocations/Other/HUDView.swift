//
//  HUDView.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/2/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import UIKit

class HUDView: UIView
{
    // Text to display
    var text = ""
    
    // Creates the HUD view
    class func hud(inView view: UIView, animated: Bool) -> HUDView
    {
        // Create HUD and set opacity
        let hudView = HUDView(frame: view.bounds)
        hudView.isOpaque = false
        
        // Add it to the view and disable user interaction
        view.addSubview(hudView)
        view.isUserInteractionEnabled = false
        
        // Animate the presentation of the view and return it
        hudView.show(animated: animated)
        return hudView
    }
    
    // Draws the box in the center of the HUD view
    override func draw(_ rect: CGRect)
    {
        // Dimensions for the box
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        // Create the box
        let boxRect = CGRect(
            x: round((bounds.size.width - boxWidth) / 2),
            y: round((bounds.size.height - boxHeight) / 2),
            width: boxWidth,
            height: boxHeight
        )
        
        // Round the corners of the box and set the color
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        // Draw the checkmark for the box
        if let image = UIImage(named: "Checkmark")
        {
            // Calculate position in the box for the image
            let imagePoint = CGPoint(
                x: center.x - round(image.size.width / 2),
                y: center.y - round(image.size.height / 2) - boxHeight / 8
            )
            
            // Add the image to the box
            image.draw(at: imagePoint)
        }
        
        // Attributes for the text to be shown in the box
        let attribs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
        NSAttributedString.Key.foregroundColor: UIColor.white]
        
        // Set the text size and location
        let textSize = text.size(withAttributes: attribs)
        let textPoint = CGPoint(
            x: center.x - round(textSize.width / 2),
            y: center.y - round(textSize.height / 2) + boxHeight / 4
        )
        
        // Add the text to the box
        text.draw(at: textPoint, withAttributes: attribs)
    }
    
    // Creates the animation used when the box is shown
    func show(animated: Bool)
    {
        // Make sure it's supposed to be animated
        if animated
        {
            // Set alpha to 0 to make it fully transparent and transform to 1.3
            // to make it scale up to a little larger than it would normally be
            alpha = 0
            transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            
            // Build the animation
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5, options: [], animations:
            {
                // Set alpha to 1 to make it fully opaque
                self.alpha = 1
                
                // Setting transform to "identity" scales it back
                // to its original size
                self.transform = CGAffineTransform.identity
            },
            
            completion: nil)
        }
    }
    
    // Hides the HUD
    func hide()
    {
        // Reenable user interaction, then remove the HUD from the view
        superview?.isUserInteractionEnabled = true
        removeFromSuperview()
    }
}
