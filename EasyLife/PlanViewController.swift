import Logging
import SafariServices
import UIKit

// sourcery: name = PlanViewController
protocol PlanViewControlling: Presentable, Segueable, Mockable {
    var viewState: PlanViewStating? { get set }

    func setDelegate(_ delegate: PlanViewControllerDelegate)
    func setTableHeaderAnimation(_ animation: RepeatColorViewAnimation)
    func setIsTableHeaderAnimating(_ isAnimating: Bool)
}

protocol PlanViewControllerDelegate: AnyObject {
    func viewController(_ viewController: PlanViewControlling, handleViewAction viewAction: ViewAction)
    func viewController(_ viewController: PlanViewControlling, prepareForSegue segue: UIStoryboardSegue)
    func viewController(_ viewController: PlanViewControlling, performAction action: PlanAction)
    func viewController(_ viewController: PlanViewControlling, didSelectItem item: TodoItem)
    func viewController(_ viewController: PlanViewControlling, performAction action: PlanItemAction,
                        onItem item: TodoItem, at indexPath: IndexPath)
}

final class PlanViewController: UIViewController, PlanViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var addButton: UIBarButtonItem!
    @IBOutlet private(set) weak var archiveButton: UIBarButtonItem!
    @IBOutlet private(set) weak var projectsButton: UIBarButtonItem!
    @IBOutlet private(set) weak var focusButton: UIBarButtonItem!
    @IBOutlet private(set) weak var tableHeaderView: UITableView!
    @IBOutlet private(set) weak var appVersionLabel: UILabel!
    @IBOutlet private(set) weak var doneLabel: UILabel!
    private var tableHeaderAnimation: RepeatColorViewAnimation?
    private weak var delegate: PlanViewControllerDelegate?
    var viewState: PlanViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: PlanCell.nibName, bundle: .main),
                           forCellReuseIdentifier: PlanCell.reuseIdentifier)
        _ = viewState.map(bind)
        tableView.applyDefaultStyleFix()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewController(self, handleViewAction: .willAppear)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.viewController(self, handleViewAction: .willDisappear)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        delegate?.viewController(self, prepareForSegue: segue)
    }

    func setDelegate(_ delegate: PlanViewControllerDelegate) {
        self.delegate = delegate
    }

    func setTableHeaderAnimation(_ animation: RepeatColorViewAnimation) {
        tableHeaderAnimation = animation
    }

    func setIsTableHeaderAnimating(_ isAnimating: Bool) {
        if isAnimating {
            tableHeaderAnimation?.start(in: tableHeaderView)
        } else {
            tableHeaderAnimation?.stop()
        }
    }

    // MARK: - private

    private func bind(_ viewState: PlanViewStating) {
        guard isViewLoaded else { return }
        appVersionLabel.text = viewState.appVersionText
        doneLabel.isHidden = viewState.isDoneHidden
        focusButton.isEnabled = viewState.isFocusButtonEnabled
        tableHeaderView.isHidden = viewState.isTableHeaderHidden
        tableHeaderView.bounds.size.height = tableView.bounds.height * viewState.tableHeaderHeightPercentage
        tableView.isHidden = viewState.isTableHidden
        tableView.reloadData()
    }

    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .add)
    }
}

// MARK: - UITableViewDelegate

extension PlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = viewState?.item(at: indexPath) else { return }
        delegate?.viewController(self, didSelectItem: item)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewState?.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let viewState = viewState, let item = viewState.item(at: indexPath) else { return nil }
        return viewState.availableActions(for: item, at: indexPath).map { itemAction in
            let action = UITableViewRowAction(
                style: viewState.style(for: itemAction),
                title: viewState.text(for: itemAction),
                handler: { _, _ in
                    self.delegate?.viewController(self, performAction: itemAction, onItem: item, at: indexPath)
                }
            )
            action.backgroundColor = viewState.color(for: itemAction)
            return action
        }
    }
}

// MARK: - UITableViewDataSource

extension PlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewState?.items(for: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cellViewState = viewState?.cellViewState(at: indexPath),
            let cell = tableView.dequeueReusableCell(withIdentifier: PlanCell.reuseIdentifier,
                                                     for: indexPath) as? PlanCell else {
                return UITableViewCell()
        }
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.numOfSections ?? 0
    }
}

// MARK: - UIScrollViewDelegate

extension PlanViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let viewState = viewState else { return }
        UIView.animate(withDuration: viewState.fadeInDuration) {
            self.appVersionLabel.alpha = 0.0
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let viewState = viewState else { return }
        UIView.animate(withDuration: viewState.fadeOutDuration) {
            self.appVersionLabel.alpha = 1.0
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableHeaderAnimation = tableHeaderAnimation, let viewState = viewState else { return }
        tableHeaderAnimation.alpha = viewState.tableHeaderAlpha(forHeight: tableHeaderView.bounds.height,
                                                                scrollOffsetY: scrollView.contentOffset.y)
    }
}
