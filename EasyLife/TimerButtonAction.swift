import Foundation

enum TimerButtonAction {
    case start
    case stop

    var title: String {
        switch self {
        case .start: return L10n.focusModeStart
        case .stop: return L10n.focusModeStop
        }
    }
}
