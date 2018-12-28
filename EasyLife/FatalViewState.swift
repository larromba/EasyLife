import Foundation

protocol FatalViewStating {
    var text: String { get }
}

struct FatalViewState: FatalViewStating {
    var text: String

    init(error: Error) {
        text = L10n.errorLoadingDataMessage(error.localizedDescription)
    }
}
