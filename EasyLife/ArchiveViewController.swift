import UIKit

class ArchiveViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var clearButton: UIBarButtonItem!
    @IBOutlet weak var thingsDoneLabel: UILabel!
    @IBOutlet weak var emptyLabelHeightLayoutConstraint: NSLayoutConstraint!

    var dataSource: ArchiveDataSource

    lazy var origEmptyLabelYConstraintHeight: CGFloat = {
        return self.emptyLabelHeightLayoutConstraint.constant
    }()

    required init?(coder aDecoder: NSCoder) {
        dataSource = ArchiveDataSource()
        super.init(coder: aDecoder)
        dataSource.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.autocapitalizationType = .none
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.load()
        tableView.applyDefaultStyleFix()
        setupNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownNotifications()
        searchBar.resignFirstResponder()
    }

    // MARK: - private

    @objc
    fileprivate func endEditing() {
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: - action

    @IBAction private func doneButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func clearButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: L10n.projectDeleteAllTitle,
                                      message: L10n.projectDeleteAllMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.projectDeleteAllOptionNo, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: L10n.projectDeleteAllOptionYes, style: .default, handler: { _ in
            self.dataSource.clearAll()
        }))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - notifications

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let height = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        tableView.contentInset.bottom = height.cgRectValue.height
        emptyLabelHeightLayoutConstraint.constant = origEmptyLabelYConstraintHeight - height.cgRectValue.height / 2.0
        view.layoutIfNeeded()
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        emptyLabelHeightLayoutConstraint.constant = origEmptyLabelYConstraintHeight
        view.layoutIfNeeded()
    }
}

// MARK: - UITableViewDelegate

extension ArchiveViewController: UITableViewDelegate {
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
        let undo = UITableViewRowAction(style: .destructive, title: L10n.archiveItemUndoOption,
                                        handler: { [weak self] (_: UITableViewRowAction, _: IndexPath) in
            self?.dataSource.undo(at: indexPath)
        })
        undo.backgroundColor = Asset.Colors.grey.color
        return [undo]
    }
}

// MARK: - UITableViewDataSource

extension ArchiveViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.section(at: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        cell.item = item
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numOfSections
    }
}

// MARK: - UISearchBarDelegate

extension ArchiveViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        dataSource.startSearch()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        dataSource.search(searchText)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        dataSource.endSearch()
    }
}

// MARK: - ArchiveDataSource

extension ArchiveViewController: TableDataSourceDelegate {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
        guard let dataSource = dataSource as? ArchiveDataSource else {
            return
        }
        tableView.reloadData()
        tableView.isHidden = dataSource.isEmpty
        clearButton.isEnabled = !dataSource.isEmpty && searchBar.text?.isEmpty ?? true
        if !dataSource.isSearching {
            searchBar.isUserInteractionEnabled = !dataSource.isEmpty
        }
        thingsDoneLabel.text = L10n.archiveItemTotalMessage(dataSource.totalItems)
    }
}
