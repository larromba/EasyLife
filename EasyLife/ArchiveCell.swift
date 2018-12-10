import UIKit

class ArchiveCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    var item: TodoItem? {
        didSet {
            if let name = item?.name, !name.isEmpty {
                titleLabel.text = item?.name
                titleLabel.textColor = .black
                return
            }
            titleLabel.text = "[no name]".localized
            titleLabel.textColor = .appleGrey
        }
    }
}
