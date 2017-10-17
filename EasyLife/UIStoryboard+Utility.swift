//
//  UIStoryboard+Utility.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

extension UIStoryboard {
    static var plan: UIStoryboard {
        return UIStoryboard(name: "Plan", bundle: nil)
    }
    
    static var archive: UIStoryboard {
        return UIStoryboard(name: "Archive", bundle: nil)
    }
    
    static var project: UIStoryboard {
        return UIStoryboard(name: "Project", bundle: nil)
    }
    
    static var components: UIStoryboard {
        return UIStoryboard(name: "Components", bundle: nil)
    }
}
