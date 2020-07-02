import UIKit

// sourcery: name = TimerButton
protocol TimerButtoning: Mockable {
    var viewState: TimerButtonViewStating? { get set }
}

final class TimerButton: UIButton, TimerButtoning {
    var viewState: TimerButtonViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    // MARK: - private

    private func bind(_ viewState: TimerButtonViewStating) {
        setTitle(viewState.title, for: .normal)
    }
}
