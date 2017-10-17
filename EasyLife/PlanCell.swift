//
//  PlanCell.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class PlanCell: UITableViewCell {
    enum ImageType {
        case none
        case noDate
        case recurring
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tagView: TagView!
 
    var iconImageType: ImageType = .none {
        didSet {
            switch iconImageType {
            case .noDate:
                iconImageView.image = #imageLiteral(resourceName: "nodate")
                iconImageView.isHidden = false
            case .recurring:
                iconImageView.image = #imageLiteral(resourceName: "recurring")
                iconImageView.isHidden = false
            default:
                iconImageView.image = nil
                iconImageView.isHidden = true
            }
        }
    }
    
    var item: TodoItem? {
        didSet {
            guard let item = item else {
                return
            }
            if item.date == nil {
                iconImageType = .noDate
            } else if item.repeatState != nil && item.repeatState != RepeatState.none {
                iconImageType = .recurring
            } else {
                iconImageType = .none
            }
            tagView.setup(for: item.project)
            if item.name == nil || item.name!.characters.count == 0 {
                titleLabel.text = "[no name]".localized
                titleLabel.textColor = UIColor.appleGrey
            } else {
                titleLabel.text = item.name
            }
        }
    }
    
    var indexPath: IndexPath? {
        didSet {
            guard let indexPath = indexPath else {
                return
            }
            switch indexPath.section {
            case 0:
                titleLabel.textColor = UIColor.lightRed
                tagView.alpha = 1.0
            case 1:
                titleLabel.textColor = UIColor.black
                tagView.alpha = 1.0
            default:
                titleLabel.textColor = UIColor.appleGrey
                tagView.alpha = 0.5
            }
        }
    }
}
