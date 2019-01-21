import Logging
import UIKit

protocol BlockedByViewControlling: Presentable, Mockable {
    var viewState: BlockedByViewStating? { get set }

    func setDelegate(_ delegate: BlockedByViewControllerDelegate)
    func reload()
    func reloadRows(at indexPath: IndexPath)
}

protocol BlockedByViewControllerDelegate: AnyObject {
    func viewControllerWillDismiss(_ viewController: BlockedByViewControlling)
    func viewController(_ viewController: BlockedByViewControlling, didSelectRowAtIndexPath indexPath: IndexPath)
}

final class BlockedByViewController: UIViewController, BlockedByViewControlling {
    @IBOutlet weak var tableView: UITableView!
    private weak var delegate: BlockedByViewControllerDelegate?

    var viewState: BlockedByViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    func setDelegate(_ delegate: BlockedByViewControllerDelegate) {
        self.delegate = delegate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.applyDefaultStyleFix()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParentViewController {
            delegate?.viewControllerWillDismiss(self)
        }
    }

    func reload() {
        tableView.reloadData()
    }

    func reloadRows(at indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .fade)
    }

    // MARK: - private

    private func bind(_ viewState: BlockedByViewStating) {
        guard isViewLoaded else { return }
    }
}

// MARK: - UITableViewDelegate

extension BlockedByViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.viewController(self, didSelectRowAtIndexPath: indexPath)
    }
}

// MARK: - UITableViewDataSource

extension BlockedByViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewState?.rowCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellViewState = viewState?.cellViewState(at: indexPath) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedCell", for: indexPath) as! BlockedCell
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.sectionCount ?? 0
    }
}
