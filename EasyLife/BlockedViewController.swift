import Logging
import UIKit

protocol BlockedViewControlling {
    var viewState: BlockedViewStating? { get set }
}

final class BlockedViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var viewState: BlockedViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.applyDefaultStyleFix()
    }

    // MARK: - private

    private func bind(_ viewState: BlockedViewStating) {
        // TODO: this
    }
}

// MARK: - UITableViewDelegate

extension BlockedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewState?.toggle(indexPath)
    }
}

// MARK: - UITableViewDataSource

extension BlockedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewState?.rowCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellViewState = viewState?.cellViewState(at: indexPath) else {
            assertionFailure("expected item")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedCell", for: indexPath) as! BlockedCell
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.sectionCount ?? 0
    }
}
