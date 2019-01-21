import UIKit

extension UITableViewRowAction {
    typealias Handler = @convention(block) (UITableViewRowAction, IndexPath) -> Void

    @discardableResult
    func fire(_ indexPath: IndexPath = IndexPath()) -> Bool {
        guard let block = value(forKey: "handler") else { return false }
        let handler = unsafeBitCast(block as AnyObject, to: Handler.self)
        handler(self, indexPath)
        return true
    }
}
