//
//  BlockedCell.swift
//  EasyLife
//
//  Created by Lee Arromba on 24/02/2018.
//  Copyright © 2018 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class BlockedCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!

    var item: TodoItem? {
        didSet {
            titleLabel.text = item?.name
        }
    }

    var isBlocked: Bool = false {
        didSet {
            iconImageView.image = isBlocked ? #imageLiteral(resourceName: "tick") : nil
        }
    }
}
