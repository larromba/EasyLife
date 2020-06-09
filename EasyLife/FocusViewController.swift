import UIKit

// sourcery: name = FocusViewController
protocol FocusViewControlling: Presentable, Mockable {
    var viewState: FocusViewStating? { get set }

    func setDelegate(_ delegate: FocusViewControllerDelegate)
}

protocol FocusViewControllerDelegate: AnyObject {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction)
    func viewController(_ viewController: FocusViewControlling, moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath)
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
        tableView.setEditing(viewState.isEditing, animated: true)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = FocusSection(rawValue: section) else { return nil }
        return viewState?.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        guard let viewState = viewState, let item = viewState.item(at: indexPath) else { return nil }
//        return viewState.availableActions(at: indexPath).map { projectAction in
//            let action = UITableViewRowAction(
//                style: viewState.style(for: projectAction),
//                title: viewState.text(for: projectAction),
//                handler: { _, _ in
//                    self.delegate?.viewController(self, performAction: projectAction, forProject: project)
//                }
//            )
//            action.backgroundColor = viewState.color(for: projectAction)
//            return action
//        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let project = viewState?.project(at: indexPath) else { return }
//        delegate?.viewController(self, performAction: .edit(project: project))
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return viewState?.canMoveRow(at: indexPath) ?? false
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate?.viewController(self, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
}

// MARK: - UITableViewDataSource

extension FocusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = FocusSection(rawValue: section) else { return 0 }
        return viewState?.items(for: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellViewState = viewState?.cellViewState(at: indexPath) else {
            assertionFailure("expected project")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "FocusCell", for: indexPath) as! FocusCell
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.numOfSections ?? 0
    }
}
