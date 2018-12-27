import UIKit

protocol TableHeaderViewing: AnyObject {
    var viewState: TableHeaderViewStating? { get set }

    func setIsAnimating(_ isAnimating: Bool)
}

final class TableHeaderView: UIView, TableHeaderViewing {
    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue {
                bounds.size.height = 0
            } else if let superview = superview, let viewState = viewState {
                bounds.size.height = superview.bounds.height * viewState.heightPercentage
            }
        }
    }
    var viewState: TableHeaderViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    func setIsAnimating(_ isAnimating: Bool) {
        if isAnimating {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    // MARK: - private

    private func bind(_ viewState: TableHeaderViewStating) {
        isHidden = viewState.isHidden
    }

    private func startAnimation() {
        guard let viewState = viewState, !viewState.isAnimating else { return }
        self.viewState = viewState.copy(isAnimating: true)
        animate()
    }

    private func stopAnimation() {
        layer.removeAllAnimations()
        viewState = viewState?.copy(isAnimating: false)
    }

    private func animate() {
        guard let viewState = viewState else { return }
        UIView.animate(withDuration: viewState.animationDuration, animations: {
            self.backgroundColor = viewState.backgroundColor
        }, completion: { _ in
            guard viewState.isAnimating else { return }
            self.viewState = viewState.copy(hue: viewState.nextHue())
            self.animate()
        })
    }
}
