import UIKit

class PlanCell: UITableViewCell {
    enum ImageType {
        case none
        case noDate
        case recurring
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var tagView: TagView!
    @IBOutlet weak var blockedView: BlockedView!

    override func awakeFromNib() {
        super.awakeFromNib()
        blockedView.blockedColor = Asset.Colors.red.color
        blockedView.blockingColor = Asset.Colors.grey.color
    }

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
            if let date = item.date {
                let timeInterval = Date().earliest.timeIntervalSince(date)
                infoLabel.text = DateComponentsFormatter.timeIntervalToString(timeInterval)
            } else {
                infoLabel.text = ""
            }
            tagView.setup(for: item.project)
            if item.name == nil || item.name!.isEmpty {
                titleLabel.text = L10n.todoItemNoName
                titleLabel.textColor = Asset.Colors.grey.color
            } else {
                titleLabel.text = item.name
            }
            if (item.blockedBy?.count ?? 0) > 0 && (item.blocking?.count ?? 0) > 0 {
                blockedView.state = .both
            } else if (item.blockedBy?.count ?? 0) > 0 {
                blockedView.state = .blocked
            } else if (item.blocking?.count ?? 0) > 0 {
                blockedView.state = .blocking
            } else {
                blockedView.state = .none
            }
            if let notes = item.notes, !notes.isEmpty {
                notesLabel.isHidden = false
            } else {
                notesLabel.isHidden = true
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
                titleLabel.textColor = Asset.Colors.red.color
                infoLabel.textColor = Asset.Colors.red.color
                notesLabel.textColor = Asset.Colors.red.color
                tagView.alpha = 1.0
                infoLabel.isHidden = true
            case 1:
                titleLabel.textColor = .black
                infoLabel.textColor = .black
                notesLabel.textColor = .black
                tagView.alpha = 1.0
                infoLabel.isHidden = true
            default: // case 2
                titleLabel.textColor = Asset.Colors.grey.color
                infoLabel.textColor = Asset.Colors.grey.color
                notesLabel.textColor = Asset.Colors.grey.color
                tagView.alpha = 0.5
                infoLabel.isHidden = false
            }
        }
    }
}
