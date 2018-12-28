import UIKit

protocol BlockedIndicatorViewStating {
    var backgroundColor: UIColor { get }
    var bottomBackgroundColor: UIColor { get }
    var isBottomViewHidden: Bool { get }
}

struct BlockedIndicatorViewState: BlockedIndicatorViewStating {
    let backgroundColor: UIColor
    let bottomBackgroundColor: UIColor
    let isBottomViewHidden: Bool

    init(state: BlockedState) {
        switch state {
        case .blocked:
            backgroundColor = Asset.Colors.red.color
            bottomBackgroundColor = .clear
            isBottomViewHidden = true
        case .blocking:
            backgroundColor = Asset.Colors.grey.color
            bottomBackgroundColor = .clear
            isBottomViewHidden = true
        case .both:
            backgroundColor = Asset.Colors.red.color
            bottomBackgroundColor = Asset.Colors.grey.color
            isBottomViewHidden = false
        case .none:
            backgroundColor = .clear
            bottomBackgroundColor = .clear
            isBottomViewHidden = true
        }
    }
}
