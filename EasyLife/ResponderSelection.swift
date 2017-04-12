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
   
    func next()
    func previous()
}

extension ResponderSelection {
    func previous() {
        var responder: UIResponder?
        for r in responders {
            if r.isFirstResponder {
                let index = responders.index(of: r)!
                if index-1 > 0 {
                    responder = responders[index-1]
                    break
                }
                responder = responders.last
                break
            }
        }
        responder?.becomeFirstResponder()
    }
    
    func next() {
        var responder: UIResponder?
        for r in responders {
            if r.isFirstResponder {
                let index = responders.index(of: r)!
                if index+1 < responders.endIndex {
                    responder = responders[index+1]
                    break
                }
                responder = responders.first
                break
            }
        }
        responder?.becomeFirstResponder()
    }
}
