import Logging
import SafariServices
import UIKit

// sourcery: name = PlanViewControllers
protocol PlanViewControlling: AnyObject, Presentable, Mockable {
    var viewState: PlanViewState? { get set }

    func setDelegate(_ delegate: PlanViewControllerDelegate)
}

protocol PlanViewControllerDelegate: AnyObject {
    func viewControllerAppeared(_ viewController: PlanViewController)
    func viewControllerDisappeared(_ viewController: PlanViewController)
    func viewControllerPressedAdd(_ viewController: PlanViewController)
    func viewController(_ viewController: PlanViewController, didSelectItem item: TodoItem)
    func viewController(_ viewController: PlanViewController, performAction action: PlanItemAction,
                        onItem item: TodoItem)
}

final class PlanViewController: UIViewController, PlanViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var addButton: UIBarButtonItem!
    @IBOutlet private(set) weak var archiveButton: UIBarButtonItem!
    @IBOutlet private(set) weak var projectsButton: UIBarButtonItem!
    @IBOutlet private(set) weak var tableHeaderView: TableHeaderView!
    @IBOutlet private(set) weak var appVersionLabel: UILabel!
    private weak var delegate: PlanViewControllerDelegate?
    var viewState: PlanViewState? {
        didSet { _ = viewState.map(bind) }
    }

    static func initialise(viewState: PlanViewState) -> PlanViewController {
        let viewController = UIStoryboard.plan.instantiateInitialViewController() as! PlanViewController
        viewController.viewState = viewState
        return viewController
    }

    func setDelegate(_ delegate: PlanViewControllerDelegate) {
        self.delegate = delegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = viewState.map(bind)
        tableView.applyDefaultStyleFix()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewControllerAppeared(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewControllerDisappeared(self)
    }

    // MARK: - private

    private func bind(_ viewState: PlanViewState) {
        guard isViewLoaded else { return }
        appVersionLabel.text = Bundle.appVersion() // TODO: this
        tableHeaderView.setupWithHeight(tableView.bounds.size.height * viewState.tableHeaderReletiveHeight)
        if viewState.isTableHeaderAnimating {
            tableHeaderView.startAnimation()
        } else {
            tableHeaderView.stopAnimation()
        }
        tableHeaderView.isHidden = !viewState.isDoneForNow // TODO: this
        tableView.isHidden = viewState.isDoneTotally // TODO: this
        tableView.reloadData()
    }

    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewControllerPressedAdd(self)
    }
}

// MARK: - UITableViewDelegate

extension PlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = viewState?.item(at: indexPath) else {
            return
        }
        delegate?.viewController(self, didSelectItem: item)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = PlanSection(rawValue: section) else { return nil }
        return viewState?.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let section = PlanSection(rawValue: indexPath.section), let item = viewState?.item(at: indexPath) else {
            assertionFailure("expected item at: \(indexPath)")
            return nil
        }
        return viewState?.availableActions(for: item, in: section).map {
            let action: UITableViewRowAction
            switch $0 {
            case .delete:
                action = UITableViewRowAction(
                    style: .destructive,
                    title: L10n.todoItemOptionDelete, // TODO: this
                    handler: { _, _ in
                        self.delegate?.viewController(self, performAction: .delete, onItem: item)
                    })
                action.backgroundColor = viewState?.deleteBackgroundColor
            case .done:
                action = UITableViewRowAction(
                    style: .normal,
                    title: L10n.todoItemOptionDone, // TODO: this
                    handler: {  _, _ in
                        self.delegate?.viewController(self, performAction: .done, onItem: item)
                    })
                action.backgroundColor = viewState?.doneBackgroundColor
            case .split:
                action = UITableViewRowAction(
                    style: .normal,
                    title: L10n.todoItemOptionSplit, // TODO: this
                    handler: {  _, _ in
                        self.delegate?.viewController(self, performAction: .split, onItem: item)
                    })
                action.backgroundColor = viewState?.splitBackgroundColor
            case .later:
                action = UITableViewRowAction(
                    style: .normal,
                    title: L10n.todoItemOptionLater, // TODO: this
                    handler: {  _, _ in
                        self.delegate?.viewController(self, performAction: .later, onItem: item)
                    })
                action.backgroundColor = viewState?.laterBackgroundColor
            }
            return action
        }
    }
}

// MARK: - UITableViewDataSource

extension PlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = PlanSection(rawValue: section) else { return 0 }
        return viewState?.items(for: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = viewState?.item(at: indexPath) else {
            assertionFailure("expected item at: \(indexPath)")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath) as! PlanCell
        cell.indexPath = indexPath
        cell.item = item // TODO: view state
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.sections.count ?? 0
    }
}

// MARK: - UIScrollViewDelegate

extension PlanViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.2) {
            self.appVersionLabel.alpha = 0.0
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.4) {
            self.appVersionLabel.alpha = 1.0
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y < 0, tableHeaderView.bounds.height > 0 else {
            return
        }
        let height = tableHeaderView.bounds.height / 4

        // TODO: viewstate?
        tableHeaderView.alphaMultiplier = max(0.0, 1.0 - (fabs(scrollView.contentOffset.y) / height))
    }
}
