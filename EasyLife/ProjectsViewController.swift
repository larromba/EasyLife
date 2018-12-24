import UIKit

protocol ProjectsViewControlling: AnyObject {
    var viewState: ProjectsViewState? { get set }

    func setDelegate(_ delegate: ProjectsViewControllerDelegate)
}

protocol ProjectsViewControllerDelegate: AnyObject {
    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectsAction)
    func viewController(_ viewController: ProjectsViewController, performAction action: ProjectItemAction,
                        forProject project: Project)
    func viewController(_ viewController: ProjectsViewController, moveRowAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath)
}

final class ProjectsViewController: UIViewController, ProjectsViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var addButton: UIBarButtonItem!
    @IBOutlet private(set) weak var editButton: UIBarButtonItem!
    @IBOutlet private(set) weak var doneButton: UIBarButtonItem!
    private weak var delegate: ProjectsViewControllerDelegate?
    var viewState: ProjectsViewState? {
        didSet { _ = viewState.map(bind) }
    }

    static func initialise(viewState: ProjectsViewState) -> ProjectsViewControlling {
        let viewController = UIStoryboard.project.instantiateInitialViewController() as! ProjectsViewController
        viewController.viewState = viewState
        return viewController
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

    private func bind(_ viewState: ProjectsViewState) {
        guard isViewLoaded else { return }
        tableView.setEditing(viewState.isEditing, animated: true)
        tableView.reloadData()
        tableView.isHidden = viewState.isEmpty
        editButton.isEnabled = viewState.isEditable
    }

    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .add)
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
        let delete = UITableViewRowAction(style: .destructive,
                                          title: viewState.deleteTitle,
                                          handler: { (_: UITableViewRowAction, _: IndexPath) in
            self.delegate?.viewController(self, performAction: .delete, forProject: project)
        })
        delete.backgroundColor = Asset.Colors.red.color
        guard let section = ProjectSection(rawValue: indexPath.section) else {
            fatalError("unhandled section \(indexPath.section)")
        }
        switch section {
        case .other:
            if viewState.isMaxPriorityItemLimitReached {
                return [delete]
            }
            let prioritize = UITableViewRowAction(style: .normal,
                                                  title: viewState.prioritizeTitle,
                                                  handler: { _, _ in
                self.delegate?.viewController(self, performAction: .prioritize, forProject: project)
            })
            prioritize.backgroundColor = viewState.prioritizeColor
            return [delete, prioritize]
        case .prioritized:
            let deprioritize = UITableViewRowAction(style: .normal,
                                                    title: viewState.deprioritizeTitle,
                                                    handler: { _, _ in
                self.delegate?.viewController(self, performAction: .deprioritize, forProject: project)
            })
            deprioritize.backgroundColor = viewState.deprioritizeColor
            return [delete, deprioritize]
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
        guard let project = viewState?.project(at: indexPath) else {
            assertionFailure("expected project")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! ProjectCell
        cell.item = project // TODO: viewstate
        cell.indexPath = indexPath
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.sections.count ?? 0
    }
}
