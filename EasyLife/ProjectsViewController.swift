import UIKit

// sourcery: name = ProjectsViewController
protocol ProjectsViewControlling: Presentable, Mockable {
    var viewState: ProjectsViewStating? { get set }

    func setDelegate(_ delegate: ProjectsViewControllerDelegate)
}

protocol ProjectsViewControllerDelegate: AnyObject {
    func viewController(_ viewController: ProjectsViewControlling, performAction action: ProjectsAction)
    func viewController(_ viewController: ProjectsViewControlling, performAction action: ProjectItemAction,
                        forProject project: Project)
    func viewController(_ viewController: ProjectsViewControlling, moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath)
}

final class ProjectsViewController: UIViewController, ProjectsViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var addButton: UIBarButtonItem!
    @IBOutlet private(set) weak var editButton: UIBarButtonItem!
    @IBOutlet private(set) weak var doneButton: UIBarButtonItem!
    private weak var delegate: ProjectsViewControllerDelegate?
    var viewState: ProjectsViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = viewState.map(bind)
        tableView.applyDefaultStyleFix()
    }

    func setDelegate(_ delegate: ProjectsViewControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - actions

    private func bind(_ viewState: ProjectsViewStating) {
        guard isViewLoaded else { return }
        tableView.reloadData()
        tableView.setEditing(viewState.isEditing, animated: true)
        tableView.isHidden = viewState.isEmpty
        editButton.isEnabled = viewState.isEditable
    }

    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .add)
    }

    @IBAction private func editButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .editTable)
    }

    @IBAction private func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .done)
    }
}

// MARK: - UITableViewDelegate

extension ProjectsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = ProjectSection(rawValue: section) else { return nil }
        return viewState?.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let viewState = viewState, let project = viewState.project(at: indexPath) else { return nil }
        return viewState.availableActions(at: indexPath).map { projectAction in
            let action = UITableViewRowAction(
                style: viewState.style(for: projectAction),
                title: viewState.text(for: projectAction),
                handler: { _, _ in
                    self.delegate?.viewController(self, performAction: projectAction, forProject: project)
                }
            )
            action.backgroundColor = viewState.color(for: projectAction)
            return action
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let project = viewState?.project(at: indexPath) else { return }
        delegate?.viewController(self, performAction: .edit(project: project))
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return viewState?.canMoveRow(at: indexPath) ?? false
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        delegate?.viewController(self, moveRowAt: sourceIndexPath, to: destinationIndexPath)
    }
}

// MARK: - UITableViewDataSource

extension ProjectsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = ProjectSection(rawValue: section) else { return 0 }
        return viewState?.items(for: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cellViewState = viewState?.cellViewState(at: indexPath),
            let cell = tableView.dequeueReusableCell(withIdentifier: ProjectCell.reuseIdentifier,
                                                     for: indexPath) as? ProjectCell else {
            return UITableViewCell()
        }
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.numOfSections ?? 0
    }
}
