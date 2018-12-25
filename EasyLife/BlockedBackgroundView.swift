import UIKit

protocol BlockedBackgroundViewing {
    var viewState: BlockedBackgroundViewStating? { get set }
}

final class BlockedBackgroundView: UIView {
    @IBOutlet private(set) weak var bottomView: UIView!
    @IBInspectable private var blockedColor: UIColor?
    @IBInspectable private var blockingColor: UIColor?

    var viewState: BlockedBackgroundViewStating? {
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

    private func bind(_ viewState: BlockedBackgroundViewStating) {
        bottomView.backgroundColor = viewState.bottomBackgroundColor
        bottomView.isHidden = viewState.isBottomViewHidden
        backgroundColor = viewState.backgroundColor
    }
}
