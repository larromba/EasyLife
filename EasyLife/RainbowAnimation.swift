import UIKit

final class RainbowAnimation: NSObject, ViewAnimation, RepeatAnimation, ColorAnimation, Mockable {
    private enum Key: String {
        case backgroundColorAnimation
    }

    private var isAnimating: Bool = false
    private var hue: CGFloat = 0
    private let minHue: CGFloat = 0
    private let maxHue: CGFloat = 360
    private let saturation: CGFloat = 1
    private let brightness: CGFloat = 1
    private let duration: TimeInterval = 1.0 / 24.0
    private var backgroundColor: UIColor {
        return UIColor(hue: hue / maxHue, saturation: saturation, brightness: brightness, alpha: 0.05 * alpha)
    }
    private weak var view: UIView?
    var alpha: CGFloat = 1

    func start(in view: UIView) {
        guard !isAnimating else { return }
        isAnimating = true
        self.view = view
        addAnimation()
    }

    func stop() {
        isAnimating = false
        view?.layer.removeAnimation(forKey: Key.backgroundColorAnimation.rawValue)
        view = nil
    }

    // MARK: - private

    private func addAnimation() {
        guard let view = view else { return }
        let animation = CABasicAnimation(keyPath: NSExpression(forKeyPath: \UIView.backgroundColor).keyPath)
        animation.duration = duration
        animation.fromValue = view.backgroundColor?.cgColor
        animation.toValue = backgroundColor.cgColor
        animation.delegate = self
        view.layer.add(animation, forKey: Key.backgroundColorAnimation.rawValue)
    }

    private func nextHue() -> CGFloat {
        var hue = self.hue + 1
        if hue > maxHue {
            hue = minHue
        }
        return hue
    }
}

// MARK: - CAAnimationDelegate

extension RainbowAnimation: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let view = view, isAnimating else { return }
        view.backgroundColor = backgroundColor
        hue = nextHue()
        addAnimation()
    }
}
