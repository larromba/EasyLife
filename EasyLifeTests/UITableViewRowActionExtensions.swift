import UIKit

private typealias RowActionHandler = @convention(block) (UITableViewRowAction, IndexPath) -> Void

extension UITableViewRowAction {
    @discardableResult
    func fire(_ indexPath: IndexPath = IndexPath()) -> Bool {
        guard let block = value(forKey: "handler") else { return false }
        let handler = unsafeBitCast(block as AnyObject, to: RowActionHandler.self)
        handler(self, indexPath)
        return true
    }
}
