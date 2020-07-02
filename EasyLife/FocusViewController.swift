import UIKit

// sourcery: name = FocusViewController
protocol FocusViewControlling: Presentable, Mockable {
    var viewState: FocusViewStating? { get set }

    func setDelegate(_ delegate: FocusViewControllerDelegate)
    func openDatePicker()
    func closeDatePicker()
    func flashTableView()
    func reloadTableViewData()
}

protocol FocusViewControllerDelegate: AnyObject {
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusAction)
    func viewController(_ viewController: FocusViewControlling, performAction action: FocusItemAction,
                        onItem item: TodoItem, at indexPath: IndexPath)
}

final class FocusViewController: UIViewController, FocusViewControlling {
    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private(set) weak var closeButton: UIBarButtonItem!
    @IBOutlet private(set) weak var timerButton: TimerButton!
    @IBOutlet private(set) weak var timeLabel: UILabel!
    private(set) lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        toolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(donePressed(_:)))
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed(_:)))
        toolbar.setItems([cancel, flexSpace, done], animated: false)
        return toolbar
    }()
    private(set) lazy var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    private(set) lazy var datePickerTextField: UITextField = {
        // using dummy text field for date picker's default open / close animations
        let textField = UITextField(frame: .zero)
        textField.inputView = pickerView
        textField.inputAccessoryView = toolbar
        view.addSubview(textField)
        return textField
    }()

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

    func openDatePicker() {
        pickerView.selectRow(viewState?.focusTime.row() ?? 0, inComponent: 0, animated: false)
        datePickerTextField.becomeFirstResponder()
    }

    func closeDatePicker() {
        view.endEditing(true)
    }

    func flashTableView() {
        tableView.alpha = 0.0
        UIView.animate(withDuration: viewState?.tableFadeAnimationDuation ?? 0) {
            self.tableView.alpha = 1.0
        }
    }

    func reloadTableViewData() {
        tableView.reloadData()
    }

    // MARK: - private

    private func bind(_ viewState: FocusViewStating) {
        guard isViewLoaded else { return }

        let halfRowHeight = (viewState.rowHeight / 2.0)
        let absMidPoint = (view.bounds.height / 2) - halfRowHeight
        var inset = tableView.contentInset
        inset.top = absMidPoint - tableView.frame.origin.y + halfRowHeight
        tableView.contentInset = inset

        view.backgroundColor = viewState.backgroundColor
        timeLabel.text = viewState.focusTime.timeStringValue()
        timerButton.viewState = viewState.timerButtonViewState
    }

    // MARK: - actions

    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .close)
    }

    @IBAction private func actionButtonPressed(_ sender: UIButton) {
        guard let viewState = timerButton.viewState else { return }
        switch viewState.action {
        case .start:
            delegate?.viewController(self, performAction: .openPicker)
        case .stop:
            delegate?.viewController(self, performAction: .stopTimer)
        }
    }

    @objc
    private func cancelPressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .closePicker)
    }

    @objc
    private func donePressed(_ sender: UIBarButtonItem) {
        delegate?.viewController(self, performAction: .startTimer)
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
        guard let viewState = viewState, let item = viewState.item else { return nil }
        return viewState.availableActions(at: indexPath).map { itemAction in
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

// MARK: - UIPickerViewDelegate

extension FocusViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewState?.pickerItem(at: row).title
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewState?.focusTime = viewState?.pickerItem(at: row).object ?? .default
    }
}

// MARK: - UIPickerViewDataSource

extension FocusViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return viewState?.numOfPickerComponents ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewState?.numOfPickerRows ?? 0
    }
}
