import UIKit

final class LayoutConstraintCache {
    private var constants = [NSLayoutConstraint: CGFloat]()

    func get(_ layoutConstraint: NSLayoutConstraint) -> CGFloat {
        return constants[layoutConstraint] ?? 0.0
    }

    func set(_ layoutConstraint: NSLayoutConstraint) {
        constants[layoutConstraint] = layoutConstraint.constant
    }

    func reset(_ layoutConstraint: NSLayoutConstraint) {
        layoutConstraint.constant = constants[layoutConstraint] ?? 0.0
    }
}
