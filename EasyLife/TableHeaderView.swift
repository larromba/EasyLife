//
//  TableHeaderView.swift
//  EasyLife
//
//  Created by Lee Arromba on 30/05/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class TableHeaderView: UIView {
    fileprivate var origBounds: CGRect?
    
    override open var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue {
                bounds.size.height = 0
            } else if let origBounds = origBounds {
                bounds.size.height = origBounds.size.height
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        origBounds = bounds
    }
}
