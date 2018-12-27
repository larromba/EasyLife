import Foundation
import UIKit

extension UIView {
    var nibView: UIView? {
        return subviews.first
    }

    func loadXib() {
        let view = makeViewFromNibNamed("\(classForCoder)")
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }

    // MARK: - Private

    private func makeViewFromNibNamed(_ name: String) -> UIView {
        let nib = UINib(nibName: name, bundle: Bundle.safeMain)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            assertionFailure("could not instantiate view for nib: \(classForCoder)")
            return UIView()
        }
        return view
    }
}
