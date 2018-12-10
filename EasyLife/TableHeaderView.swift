import UIKit
import AVFoundation

class TableHeaderView: UIView {
    override open var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue {
                bounds.size.height = 0
            } else {
                bounds.size.height = origBounds.size.height
            }
        }
    }
    var alphaMultiplier: CGFloat = 1

    private var origBounds: CGRect = .zero
    private var hue: CGFloat = 0
    private var isAnimating = false

    func setupWithHeight(_ height: CGFloat) {
        origBounds = CGRect(x: frame.origin.x, y: frame.origin.y, width: bounds.size.width, height: height)
    }

    func startAnimation() {
        isAnimating = true
        UIView.animate(withDuration: 1/24, animations: {
            self.backgroundColor = UIColor(hue: self.hue/360, saturation: 1, brightness: 1, alpha: 0.05 * self.alphaMultiplier)
        }, completion: { _ in
            guard self.isAnimating else {
                return
            }
            self.hue += 1
            if self.hue > 360 {
                self.hue = 0
            }
            self.startAnimation()
        })
    }

    func stopAnimation() {
        isAnimating = false
    }
}
