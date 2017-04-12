//
//  UIStoryboard+Utility.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

extension UIStoryboard {
    class func main() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
    
    class func components() -> UIStoryboard {
        return UIStoryboard(name: "Components", bundle: nil)
    }
}
