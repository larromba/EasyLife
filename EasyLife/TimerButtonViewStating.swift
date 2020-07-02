import Foundation

protocol TimerButtonViewStating {
    var action: TimerButtonAction { get }
    var title: String { get }
}

struct TimerButtonViewState: TimerButtonViewStating {
    let action: TimerButtonAction
    var title: String {
        return action.title
    }
}
