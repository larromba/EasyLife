import UIKit

protocol TableHeaderViewStating {
    var isHidden: Bool { get }
    var isAnimating: Bool { get }
    var alpha: CGFloat { get }
    var heightPercentage: CGFloat { get }
    var hue: CGFloat { get }
    var minHue: CGFloat { get }
    var maxHue: CGFloat { get }
    var saturation: CGFloat { get }
    var brightness: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var backgroundColor: UIColor { get }

    func alpha(forHeight height: CGFloat, scrollOffsetY: CGFloat) -> CGFloat
    func nextHue() -> CGFloat

    func copy(alpha: CGFloat) -> TableHeaderViewStating
    func copy(isAnimating: Bool) -> TableHeaderViewStating
    func copy(hue: CGFloat) -> TableHeaderViewStating
}

struct TableHeaderViewState: TableHeaderViewStating {
    let isHidden: Bool = false
    let isAnimating: Bool
    let alpha: CGFloat
    let heightPercentage: CGFloat = 0.3
    let hue: CGFloat
    let minHue: CGFloat = 0
    let maxHue: CGFloat = 360
    let saturation: CGFloat = 1
    let brightness: CGFloat = 1
    let animationDuration: TimeInterval = 1.0 / 24.0
    var backgroundColor: UIColor {
        return UIColor(hue: hue / maxHue, saturation: saturation, brightness: brightness, alpha: 0.05 * alpha)
    }

    func alpha(forHeight height: CGFloat, scrollOffsetY: CGFloat) -> CGFloat {
        guard scrollOffsetY < 0.0, height > 0.0 else { return 0.0 }
        return max(0.0, 1.0 - (fabs(scrollOffsetY) / (height / 4.0)))
    }

    func nextHue() -> CGFloat {
        var hue = self.hue + 1
        if hue > maxHue {
            hue = minHue
        }
        return hue
    }
}

extension TableHeaderViewState {
    func copy(alpha: CGFloat) -> TableHeaderViewStating {
        return TableHeaderViewState(isAnimating: isAnimating, alpha: alpha, hue: hue)
    }

    func copy(isAnimating: Bool) -> TableHeaderViewStating {
        return TableHeaderViewState(isAnimating: isAnimating, alpha: alpha, hue: hue)
    }

    func copy(hue: CGFloat) -> TableHeaderViewStating {
        return TableHeaderViewState(isAnimating: isAnimating, alpha: alpha, hue: hue)
    }
}
