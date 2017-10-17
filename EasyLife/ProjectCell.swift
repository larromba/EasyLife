//
//  ProjectCell.swift
//  EasyLife
//
//  Created by Lee Arromba on 01/09/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class ProjectCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagView: TagView!
    
    var item: Project? {
        didSet {
            titleLabel.text = item?.name
            tagView.setup(for: item)
        }
    }
    
    var indexPath: IndexPath? {
        didSet {
            guard let indexPath = indexPath else {
                return
            }
            switch indexPath.section {
            case 1:
                titleLabel.textColor = UIColor.appleGrey
            default:
                titleLabel.textColor = UIColor.black
            }
        }
    }
}
