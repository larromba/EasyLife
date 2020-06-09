import UIKit

// sourcery: name = FocusViewController
protocol FocusViewControlling: Presentable, Mockable {
    var viewState: FocusViewStating? { get set }

    func setDelegate(_ delegate: FocusViewControllerDelegate)
}

protocol FocusViewControllerDelegate: AnyObject {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction)
}

final class FocusViewController: UIViewController, FocusViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var closeButton: UIBarButtonItem!
    private weak var delegate: FocusViewControllerDelegate?
    var viewState: FocusViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: PlanCell.nibName, bundle: .main),
                           forCellReuseIdentifier: PlanCell.reuseIdentifier)
        _ = viewState.map(bind)
        tableView.applyDefaultStyleFix()
    }

    func setDelegate(_ delegate: FocusViewControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - actions

    private func bind(_ viewState: FocusViewStating) {
        guard isViewLoaded else { return }
        tableView.reloadData()

        var inset = tableView.contentInset
        inset.top = (tableView.bounds.height / 2) - (viewState.rowHeight / 2.0)
        tableView.contentInset = inset

        view.backgroundColor = viewState.backgroundColor
    }

    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .close)
    }
}

// MARK: - UITableViewDelegate

extension FocusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0.0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let viewState = viewState else { return nil }
        return viewState.availableActions(at: indexPath).map { projectAction in
            let action = UITableViewRowAction(
                style: viewState.style(for: projectAction),
                title: viewState.text(for: projectAction),
                handler: { _, _ in
                    //self.delegate?.viewController(self, performAction: projectAction, forProject: project)
                }
            )
            action.backgroundColor = viewState.color(for: projectAction)
            return action
        }
    }
}

// MARK: - UITableViewDataSource

extension FocusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewState?.totalItems ?? 0
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
