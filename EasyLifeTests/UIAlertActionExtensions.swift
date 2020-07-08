import UIKit

private typealias AlertActionHandler = @convention(block) (UIAlertAction) -> Void

extension UIAlertAction {
    @discardableResult
    func fire() -> Bool {
        guard let block = value(forKey: "handler") else { return false }
        let handler = unsafeBitCast(block as AnyObject, to: AlertActionHandler.self)
        handler(self)
        return true
    }
}
