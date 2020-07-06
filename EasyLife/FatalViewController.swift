import UIKit

// sourcery: name = FatalViewController
protocol FatalViewControlling: AnyObject, Mockable {
    var viewState: FatalViewStating? { get set }
}

final class FatalViewController: UIViewController {
    @IBOutlet private(set) weak var label: UILabel!

    var viewState: FatalViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = viewState.map(bind)
    }

    // MARK: - private

    private func bind(_ viewState: FatalViewStating) {
        guard isViewLoaded else { return }
        label.text = viewState.text
    }
}
