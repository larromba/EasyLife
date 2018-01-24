//
//  ArchiveCell.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class ArchiveCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    var item: TodoItem? {
        didSet {
            if item?.name?.isEmpty == true {
                titleLabel.text = "[no name]".localized
                titleLabel.textColor = UIColor.appleGrey
                return
            }
            titleLabel.text = item?.name
        }
    }
}
