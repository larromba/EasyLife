import UIKit

protocol AlertActionFactoring {
    func make(withTitle title: String?, style: UIAlertAction.Style,
              handler: ((UIAlertAction) -> Void)?) -> UIAlertAction
}

final class AlertActionFactory: AlertActionFactoring {
    func make(withTitle title: String?, style: UIAlertAction.Style,
              handler: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
}
