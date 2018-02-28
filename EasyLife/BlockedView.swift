//
//  BlockedView.swift
//  EasyLife
//
//  Created by Lee Arromba on 27/02/2018.
//  Copyright © 2018 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class BlockedView: UIView {
    enum BlockedState {
        case blocked
        case blocking
        case both
        case none
    }

    @IBOutlet weak var bottomView: UIView!

    @IBInspectable var blockedColor: UIColor?
    @IBInspectable var blockingColor: UIColor?
    var state: BlockedState = .none {
        didSet {
            switch state {
            case .blocked:
                backgroundColor = blockedColor
                bottomView.isHidden = true
            case .blocking:
                backgroundColor = blockingColor
                bottomView.isHidden = true
            case .both:
                backgroundColor = blockedColor
                bottomView.backgroundColor = blockingColor
                bottomView.isHidden = false
            case .none:
                backgroundColor = .clear
                bottomView.backgroundColor = .clear
                bottomView.isHidden = true
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
    }
}
