//
//  UITextView+Style.swift
//  EasyLife
//
//  Created by Lee Arromba on 13/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

extension UITextView {
    func applyAppleStyle() {
        layer.cornerRadius = 5.0
        layer.borderColor = UIColor.appleGrey.cgColor
        layer.borderWidth = 0.5
        textContainerInset.left = 2.0
        textContainerInset.right = 2.0
    }
}
