import UIKit

protocol ArchiveViewControlling: AnyObject, Presentable, Mockable {
    var viewState: ArchiveViewStating? { get set }

    func setDelegate(_ delegate: ArchiveViewControllerDelegate)
    func endEditing()
}

protocol ArchiveViewControllerDelegate: AnyObject {
    func viewController(_ viewController: ArchiveViewController, performAction action: ArchiveAction)
    func viewControllerStartedSearch(_ viewController: ArchiveViewController)
    func viewController(_ viewController: ArchiveViewController, performSearch term: String)
    func viewControllerEndedSearch(_ viewController: ArchiveViewController)
    func viewControllerTapped(_ viewController: ArchiveViewController)
}

final class ArchiveViewController: UIViewController, ArchiveViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var searchBar: UISearchBar!
    @IBOutlet private(set) weak var doneButton: UIBarButtonItem!
    @IBOutlet private(set) weak var clearButton: UIBarButtonItem!
    @IBOutlet private(set) weak var thingsDoneLabel: UILabel!
    @IBOutlet private(set) weak var emptyLabelVerticalLayoutConstraint: NSLayoutConstraint! {
        didSet { layoutConstraintCache.set(emptyLabelVerticalLayoutConstraint) }
    }
    private let layoutConstraintCache = LayoutConstraintCache()
    private weak var delegate: ArchiveViewControllerDelegate?
    var viewState: ArchiveViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = viewState.map(bind)
        searchBar.autocapitalizationType = .none // this is specified in nib, but somehow still needed...
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        tableView.applyDefaultStyleFix()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownNotifications()
        endEditing()
    }

    func setDelegate(_ delegate: ArchiveViewControllerDelegate) {
        self.delegate = delegate
    }

    func endEditing() {
        view.endEditing(true)
    }

    // MARK: - private

    private func bind(_ viewState: ArchiveViewStating) {
        guard isViewLoaded else { return }
        tableView.reloadData()
        tableView.isHidden = viewState.isEmpty
        searchBar.text = viewState.text
        clearButton.isEnabled = viewState.isClearButtonEnabled
        searchBar.isUserInteractionEnabled = viewState.isSearchBarEnabled
        thingsDoneLabel.text = viewState.doneText
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

    @objc
    private func viewTapped(_ sender: UITapGestureRecognizer) {
        delegate?.viewControllerTapped(self)
    }

    // MARK: - action

    @IBAction private func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .done)
    }

    @IBAction private func clearButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .clear)
    }

    // MARK: - notifications

    // TODO: keyboard notif object?
    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let height = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        tableView.contentInset.bottom = height.cgRectValue.height
        let originalValue = layoutConstraintCache.get(emptyLabelVerticalLayoutConstraint)
        emptyLabelVerticalLayoutConstraint.constant = originalValue - height.cgRectValue.height / 2.0
        view.layoutIfNeeded()
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        layoutConstraintCache.reset(emptyLabelVerticalLayoutConstraint)
        view.layoutIfNeeded()
    }
}

// MARK: - UITableViewDelegate

extension ArchiveViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewState?.rowHeight ?? 0.0
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewState?.title(for: section)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let item = self.viewState?.item(at: indexPath) else { return nil }
        let undo = UITableViewRowAction(
            style: .destructive,
            title: viewState?.undoTitle,
            handler: { _, _ in
                self.delegate?.viewController(self, performAction: .undo(item))
            })
        undo.backgroundColor = viewState?.undoBackgroundColor
        return [undo]
    }
}

// MARK: - UITableViewDataSource

extension ArchiveViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewState?.section(at: section)?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellViewState = viewState?.cellViewState(at: indexPath) else {
            assertionFailure("expected item")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArchiveCell", for: indexPath) as! ArchiveCell
        cell.viewState = cellViewState
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewState?.numOfSections ?? 0
    }
}

// MARK: - UISearchBarDelegate

extension ArchiveViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        delegate?.viewControllerStartedSearch(self)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewState = viewState?.copy(text: searchText)
        delegate?.viewController(self, performSearch: searchText)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        delegate?.viewControllerEndedSearch(self)
    }
}
