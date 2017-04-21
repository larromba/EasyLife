//
//  UIColor+Style.swift
//  EasyLife
//
//  Created by Lee Arromba on 13/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

extension UIColor {
    class var appleGrey: UIColor {
        return r(205.0, g: 205.0, b: 205.0)
    }
    
    class var lightGreen: UIColor {
        return r(116.0, g: 230.0, b: 131.0)
    }
    
    class var lightRed: UIColor {
        return r(230.0, g: 98.0, b: 88.0)
    }
    
    // MARK: - private
    
    fileprivate class func r(_ r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}
