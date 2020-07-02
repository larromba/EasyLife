import Foundation

protocol FatalViewStating {
    var text: String { get }
}

struct FatalViewState: FatalViewStating {
    let text: String

    init(error: Error) {
        text = L10n.errorLoadingDataMessage(error.localizedDescription)
    }
}
