import UIKit

class ProjectsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    var dataSource: ProjectsDataSource

    required init?(coder aDecoder: NSCoder) {
        dataSource = ProjectsDataSource()
        super.init(coder: aDecoder)
        dataSource.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.load()
        tableView.applyDefaultStyleFix()
    }

    // MARK: - private

    private func newProject() {
        let alertController = UIAlertController(title: L10n.newProjectAlertTitle, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) in
            textField.placeholder = L10n.newProjectAlertName
            textField.clearButtonMode = .whileEditing
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }
        alertController.addAction(UIAlertAction(title: L10n.newProjectAlertCancel, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: L10n.newProjectAlertOk, style: .default,
                                                handler: { (_: UIAlertAction) in
            guard let name = alertController.textFields?.first?.text else {
                return
            }
            self.dataSource.addProject(name: name)
        }))
        alertController.actions[1].isEnabled = false
        present(alertController, animated: true, completion: nil)
    }

    fileprivate func editProject(at indexPath: IndexPath) {
        let name = dataSource.name(at: indexPath)
        let alertController = UIAlertController(title: L10n.editProjectAlertTitle, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) in
            textField.placeholder = L10n.editProjectAlertName
            textField.text = name
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
            textField.clearButtonMode = .whileEditing
        }
        alertController.addAction(UIAlertAction(title: L10n.editProjectAlertCancel, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: L10n.editProjectAlertOk, style: .default,
                                                handler: { (_: UIAlertAction) in
            guard let name = alertController.textFields?.first?.text else {
                return
            }
            self.dataSource.updateName(name: name, at: indexPath)
        }))
        alertController.actions[1].isEnabled = true
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - actions

    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        newProject()
    }

    @IBAction private func editButtonPressed(_ sender: UIBarButtonItem) {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }

    @IBAction private func doneButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func textFieldDidChange(_ textField: UITextField) { // FIXME: public for unit test (sendEvents doesnt work)
        guard let alertController = presentedViewController as? UIAlertController else {
            return
        }
        alertController.actions[1].isEnabled = (textField.text?.isEmpty == false)
    }
}

// MARK: - UITableViewDelegate

extension ProjectsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive,
                                          title: L10n.todoItemOptionDelete,
                                          handler: { (_: UITableViewRowAction, _: IndexPath) in
            self.dataSource.delete(at: indexPath)
        })
        delete.backgroundColor = Asset.Colors.red.color
        switch indexPath.section {
        case 1:
            if dataSource.isMaxPriorityItemLimitReached {
                return [delete]
            }
            let prioritize = UITableViewRowAction(style: .normal,
                                                  title: L10n.projectOptionPrioritize,
                                                  handler: { (_: UITableViewRowAction, _: IndexPath) in
                self.dataSource.prioritize(at: indexPath)
            })
            prioritize.backgroundColor = Asset.Colors.green.color
            return [delete, prioritize]
        default:
            let deprioritize = UITableViewRowAction(style: .normal,
                                                    title: L10n.projectOptionDeprioritize,
                                                    handler: { (_: UITableViewRowAction, _: IndexPath) in
                self.dataSource.deprioritize(at: indexPath)
            })
            deprioritize.backgroundColor = Asset.Colors.grey.color
            return [delete, deprioritize]
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editProject(at: indexPath)
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 ||
            (indexPath.section == 1 && !dataSource.isMaxPriorityItemLimitReached && dataSource.totalPriorityItems > 0)
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section == 0, destinationIndexPath.section == 1 {
            dataSource.deprioritize(at: sourceIndexPath)
        } else if (sourceIndexPath.section == 0 && destinationIndexPath.section == 0) ||
            (sourceIndexPath.section == 1 && destinationIndexPath.section == 0) {
            dataSource.move(fromPath: sourceIndexPath, toPath: destinationIndexPath)
        }
    }
}

// MARK: - UITableViewDataSource

extension ProjectsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.section(at: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! ProjectCell
        cell.item = item
        cell.indexPath = indexPath
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.sections.count
    }
}

// MARK: - TableDataSource

extension ProjectsViewController: TableDataSourceDelegate {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
        guard let dataSource = dataSource as? ProjectsDataSource else {
            return
        }
        tableView.reloadData()
        tableView.isHidden = dataSource.isEmpty
        editButton.isEnabled = !dataSource.isEmpty
    }
}
