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
    var nextResponderInArray: UIResponder? { get }
    var previousResponderInArray: UIResponder? { get }
    
    func nextResponderBecomeFirst()
    func previousResponderBecomeFirst()
}

extension ResponderSelection {
    var currentResponder: UIResponder? {
        for responder in responders {
            if responder.isFirstResponder {
                return responder
            }
        }
        return nil
    }
    
    var nextResponderInArray: UIResponder? {
        if let currentResponder = currentResponder {
            return nextResponder(after: currentResponder)
        }
        return nil
    }
    
    var previousResponderInArray: UIResponder? {
        if let currentResponder = currentResponder {
            return previousResponder(before: currentResponder)
        }
        return nil
    }
    
    func nextResponderBecomeFirst() {
        nextResponderInArray?.becomeFirstResponder()
    }
    
    func previousResponderBecomeFirst() {
        previousResponderInArray?.becomeFirstResponder()
    }
    
    func nextResponder(after responder: UIResponder) -> UIResponder? {
        guard let index = responders.index(of: responder) else {
            return nil
        }
        let nextResponder: UIResponder
        if index+1 < responders.endIndex {
            nextResponder = responders[index+1]
        } else {
            nextResponder = responders.first!
        }
        if nextResponder.canBecomeFirstResponder {
            return nextResponder
        }
        return self.nextResponder(after: nextResponder)
    }
    
    func previousResponder(before responder: UIResponder) -> UIResponder? {
        guard let index = responders.index(of: responder) else {
            return nil
        }
        let prevResponder: UIResponder
        if index-1 >= responders.startIndex {
            prevResponder = responders[index-1]
        } else {
            prevResponder = responders.last!
        }
        if prevResponder.canBecomeFirstResponder {
            return prevResponder
        }
        return previousResponder(before: prevResponder)
    }
}
