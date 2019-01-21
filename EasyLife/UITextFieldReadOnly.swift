import UIKit

private var key: Void?

// swiftlint:disable line_length
// @see http://stackoverflow.com/questions/6701019/how-to-disable-copy-paste-option-from-uitextfield-programmatically/28833795#28833795
extension UITextField {
    var readOnly: Bool {
        get { return additions.readOnly }
        set { additions.readOnly = newValue }
    }

    // swiftlint:disable override_in_extension
    open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        guard !readOnly &&
            (!(action == #selector(UIResponderStandardEditActions.paste(_:))) ||
            !(action == #selector(UIResponderStandardEditActions.cut(_:)))) else {
                return nil
        }
        return super.target(forAction: action, withSender: sender)
    }

    // MARK: - private

    private class Additions: NSObject {
        var readOnly: Bool = false
    }

    private var additions: Additions {
        guard let additions = objc_getAssociatedObject(self, &key) as? Additions else {
            let additions = Additions()
            objc_setAssociatedObject(self, &key, additions, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return additions
        }
        return additions
    }
}
