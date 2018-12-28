import UIKit

protocol FatalViewControlling: AnyObject {
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
        label.text = viewState.text
    }
}
