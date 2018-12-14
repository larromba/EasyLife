import UIKit

private var key: Void?

// swiftlint:disable line_length
// @see http://stackoverflow.com/questions/6701019/how-to-disable-copy-paste-option-from-uitextfield-programmatically/28833795#28833795
extension UITextField {
    fileprivate class Additions: NSObject {
        var readonly: Bool = false
    }

    var readonly: Bool {
        get {
            return additions.readonly
        } set {
            additions.readonly = newValue
        }
    }

    open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        guard !readonly &&
            (!(action == #selector(UIResponderStandardEditActions.paste(_:))) ||
            !(action == #selector(UIResponderStandardEditActions.cut(_:)))) else {
                return nil
        }
        return super.target(forAction: action, withSender: sender)
    }

    // MARK: - private

    private var additions: Additions {
        if let additions = objc_getAssociatedObject(self, &key) as? Additions {
            return additions
        }
        let additions = Additions()
        objc_setAssociatedObject(self, &key, additions, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        return additions
    }
}
