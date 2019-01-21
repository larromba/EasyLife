import UIKit

extension UITableView {
    func scrollUp(by value: Int) {
        setContentOffset(CGPoint(x: 0, y: value), animated: false)
    }
}
