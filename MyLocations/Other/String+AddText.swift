//
//  String+AddText.swift
//  MyLocations
//
//  Created by Jeffery Trotz on 4/17/19.
//  Copyright © 2019 Jeffery Trotz. All rights reserved.
//

import Foundation

extension String
{
    // Mutating = changes value of a struct
    // Used to convert placemark into a string
    mutating func add(text: String?, separatedBy separator: String = "")
    {
        // If text isn't empy, add to itself
        if let text = text
        {
            if !isEmpty
            {
                self += separator
            }
            
            self += text
        }
    }
}
