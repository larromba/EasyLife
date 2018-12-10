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
