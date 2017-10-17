//
//  UIView+Xib.swift
//  EasyLife
//
//  Created by Lee Arromba on 11/10/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import Foundation

//
//  UIViewExtensions.swift
//  EasyMusic
//
//  Created by Lee Arromba on 10/11/2015.
//  Copyright © 2015 Lee Arromba. All rights reserved.
//

import UIKit

extension UIView {
    func loadXib() {
        let view = createViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(view)
    }
    
    func nibView() -> UIView? {
        return subviews.first
    }
    
    // MARK: - Private
    
    fileprivate func createViewFromNib() -> UIView {
        let nib = UINib(nibName: "\(classForCoder)", bundle: Bundle.safeMain)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("can't load view for \(self)")
        }
        return view
    }
}
