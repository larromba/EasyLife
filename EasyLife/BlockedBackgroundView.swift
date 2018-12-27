import UIKit

protocol BlockedIndicatorViewing {
    var viewState: BlockedIndicatorViewStating? { get set }
}

final class BlockedIndicatorView: UIView {
    @IBOutlet private(set) weak var bottomView: UIView!
    @IBInspectable private var blockedColor: UIColor?
    @IBInspectable private var blockingColor: UIColor?

    var viewState: BlockedIndicatorViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadXib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadXib()
    }

    // MARK: - private

    private func bind(_ viewState: BlockedIndicatorViewStating) {
        // TODO: check
        bottomView.backgroundColor = viewState.bottomBackgroundColor
        bottomView.isHidden = viewState.isBottomViewHidden
        backgroundColor = viewState.backgroundColor
    }
}
