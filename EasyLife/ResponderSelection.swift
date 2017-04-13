//
//  ResponderSelection.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

protocol ResponderSelection {
    var responders: [UIResponder]! { get set }
    var currentResponder: UIResponder? { get }
    var nextResponder: UIResponder? { get }
    var previousResponder: UIResponder? { get }
    
    func next()
    func previous()
}

extension ResponderSelection {
    var currentResponder: UIResponder? {
        for r in responders {
            if r.isFirstResponder {
                return r
            }
        }
        return nil
    }
    
    var nextResponder: UIResponder? {
        var responder: UIResponder?
        if let current = currentResponder {
            let index = responders.index(of: current)!
            if index+1 < responders.endIndex {
                responder = responders[index+1]
            } else {
                responder = responders.first
            }
        }
        return responder
    }
    
    var previousResponder: UIResponder? {
        var responder: UIResponder?
        if let current = currentResponder {
            let index = responders.index(of: current)!
            if index-1 >= responders.startIndex {
                responder = responders[index-1]
            } else {
                responder = responders.last
            }
        }
        return responder
    }
    
    func next() {
        nextResponder?.becomeFirstResponder()
    }
    
    func previous() {
        previousResponder?.becomeFirstResponder()
    }
}
