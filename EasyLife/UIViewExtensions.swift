import Foundation
import UIKit

extension UIView {
    func loadXib() {
        let view = createViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(view)
    }

    func nibView() -> UIView? {
        return subviews.first
    }

    // MARK: - Private

    fileprivate func createViewFromNib() -> UIView {
        let nib = UINib(nibName: "\(classForCoder)", bundle: Bundle.safeMain)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("can't load view for \(self)")
        }
        return view
    }
}
