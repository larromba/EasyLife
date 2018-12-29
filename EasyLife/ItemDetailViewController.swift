import PPBadgeView
import UIKit

protocol ItemDetailViewControlling: AnyObject, ResponderSelection, Presentable {
    var viewState: ItemDetailViewState? { get set }

    func setDelegate(_ delegate: ItemDetailViewControllerDelegate)
}

protocol ItemDetailViewControllerDelegate: AnyObject {
    func viewControllerWillAppear(_ viewController: ItemDetailViewControlling)
    func viewController(_ viewController: ItemDetailViewControlling, performAction action: ItemDetailAction)
    func viewController(_ viewController: ItemDetailViewControlling, updatedState state: ItemDetailViewState)
    func viewControllerWillDismiss(_ viewController: ItemDetailViewControlling)
}

final class ItemDetailViewController: UIViewController, ItemDetailViewControlling {
    @IBOutlet private(set) weak var titleTextField: UITextField!
    @IBOutlet private(set) weak var dateTextField: UITextField!
    @IBOutlet private(set) weak var repeatsTextField: UITextField!
    @IBOutlet private(set) weak var projectTextField: UITextField!
    @IBOutlet private(set) weak var textView: UITextView!
    @IBOutlet private(set) weak var blockedButton: UIBarButtonItem!
    @IBOutlet private(set) weak var scrollView: UIScrollView!
    private lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        toolbar.barStyle = .default
        let prev = UIBarButtonItem(image: Asset.Assets.backwardArrow.image, style: .plain, target: self,
                                   action: #selector(prevPressed(_:)))
        let next = UIBarButtonItem(image: Asset.Assets.forwardArrow.image, style: .plain, target: self,
                                   action: #selector(nextPressed(_:)))
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 10.0
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed(_:)))
        toolbar.setItems([prev, spacer, next, spacer, flexSpace, spacer, done], animated: false)
        return toolbar
    }()
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dateTapped(_:)))
        tap.numberOfTapsRequired = 2
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        datePicker.addGestureRecognizer(tap)
        return datePicker
    }()
    private lazy var simpleDatePicker = SimpleDatePicker(delegate: self)
    private lazy var repeatPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    private lazy var projectPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    private var calendarButton: UIBarButtonItem?
    private weak var delegate: ItemDetailViewControllerDelegate?
    var responders: [UIResponder]!
    var viewState: ItemDetailViewState? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        responders = [
            titleTextField,
            dateTextField,
            repeatsTextField,
            projectTextField,
            textView
        ]
        projectTextField.inputView = projectPicker
        projectTextField.inputAccessoryView = toolbar
        repeatsTextField.inputView = repeatPicker
        repeatsTextField.inputAccessoryView = toolbar
        dateTextField.inputView = simpleDatePicker
        dateTextField.inputAccessoryView = toolbar
        dateTextField.readOnly = true
        titleTextField.inputAccessoryView = toolbar
        titleTextField.readOnly = true
        textView.inputAccessoryView = toolbar
        textView.applyTextFieldStyle()
        textView.dataDetectorTypes = .all
        textView.isEditable = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesEnded = false
        textView.addGestureRecognizer(tapGesture)
        _ = viewState.map(bind)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewControllerWillAppear(self)
        setupNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParentViewController {
            delegate?.viewControllerWillDismiss(self)
        }
        tearDownNotifications()
        view.endEditing(true)
    }

    func setDelegate(_ delegate: ItemDetailViewControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func bind(_ viewState: ItemDetailViewState) {
        guard isViewLoaded else { return }

        datePicker.minimumDate = viewState.minimumDate
        simpleDatePicker.viewState = viewState.simpleDatePickerViewState
        switch viewState.leftButton {
        case .cancel:
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                                               action: #selector(cancelPressed(_:)))
        case .back:
            navigationItem.leftBarButtonItem = nil
        }
        switch viewState.rightButton {
        case .save:
            navigationItem.rightBarButtonItems?.replace(UIBarButtonItem(barButtonSystemItem: .save, target: self,
                                                                        action: #selector(savePressed(_:))), at: 0)
        case .delete:
            navigationItem.rightBarButtonItems?.replace(UIBarButtonItem(barButtonSystemItem: .trash, target: self,
                                                                        action: #selector(deletePressed(_:))), at: 0)
        }
        titleTextField.text = viewState.name
        textView.text = viewState.notes
        dateTextField.text = viewState.dateString
        repeatsTextField.text = viewState.repeatState?.stringValue()
        projectTextField.text = viewState.project?.name
        projectTextField.isUserInteractionEnabled = viewState.isProjectTextFieldEnabled
        projectTextField.alpha = viewState.projectTextFieldAlpha
        blockedButton.isEnabled = viewState.isBlockedButtonEnabled
        blockedButton.pp.addBadge(number: viewState.blockedCount)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    private func makeFirstResponder(_ responder: UIResponder?) {
        if responder == textView { textView.isEditable = true }
        responder?.becomeFirstResponder()
    }

    private func addCalendarButton() {
        guard calendarButton == nil else { return }
        switch dateTextField.inputView {
        case datePicker:
            calendarButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self,
                                             action: #selector(calendarButtonPressed(_:)))
        case simpleDatePicker:
            calendarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self,
                                             action: #selector(calendarButtonPressed(_:)))
        default:
            assertionFailure("unexpected dateTextField.inputView")
            return
        }
        toolbar.items?.insert(calendarButton!, at: 4)
    }

    private func removeCalendarButton() {
        guard let calendarButton = calendarButton, let index = toolbar.items?.firstIndex(of: calendarButton) else {
            return
        }
        toolbar.items?.remove(at: index)
        self.calendarButton = nil
    }

    private func toggleCalendarButton() {
        removeCalendarButton()
        addCalendarButton()
    }

    // MARK: - action

    @IBAction private func savePressed(_ sender: UIBarButtonItem?) {
        delegate?.viewController(self, performAction: .save)
    }

    @IBAction private func cancelPressed(_ sender: UIBarButtonItem?) {
        delegate?.viewController(self, performAction: .cancel)
    }

    @IBAction private func deletePressed(_ sender: UIBarButtonItem?) {
        delegate?.viewController(self, performAction: .delete)
    }

    @objc
    private func prevPressed(_ sender: UIBarButtonItem) {
        makeFirstResponder(previousResponderInArray)
    }

    @objc
    private func nextPressed(_ sender: UIBarButtonItem) {
        makeFirstResponder(nextResponderInArray)
    }

    @objc
    private func donePressed(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }

    @objc
    private func dateChanged(_ sender: UIDatePicker) {
        viewState?.date = sender.date
        notifyStateUpdated()
    }

    @objc
    private func dateTapped(_ sender: UITapGestureRecognizer) {
        viewState?.date = datePicker.date
        notifyStateUpdated()
    }

    @objc
    private func textViewTapped(_ sender: UIDatePicker) {
        makeFirstResponder(textView)
    }

    @objc
    private func calendarButtonPressed(_ sender: UIBarButtonItem) {
        switch dateTextField.inputView {
        case datePicker:
            dateTextField.inputView = simpleDatePicker
        case simpleDatePicker:
            dateTextField.inputView = datePicker
        default:
            assertionFailure("unexpected input view")
            return
        }
        dateTextField.reloadInputViews()
        toggleCalendarButton()
    }

    @IBAction private func textFieldChanged(_ sender: UITextField) {
        viewState?.name = sender.text
        notifyStateUpdated()
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let height = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        scrollView.contentInset.bottom = height.cgRectValue.height
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }

    private func notifyStateUpdated() {
        guard let viewState = viewState else { return }
        delegate?.viewController(self, updatedState: viewState)
    }
}

// MARK: - UIPickerViewDelegate

extension ItemDetailViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case repeatPicker:
            return viewState?.repeatStatePickerComponent(at: row).title
        case projectPicker:
            return viewState?.projectPickerComponent(at: row).title
        default:
            assertionFailure("unhandled picker")
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case repeatPicker:
            viewState?.repeatState = viewState?.repeatStatePickerComponent(at: row).object
        case projectPicker:
            viewState?.project = viewState?.projectPickerComponent(at: row).object
        default:
            assertionFailure("unhandled picker")
        }
        notifyStateUpdated()
    }
}

// MARK: - UIPickerViewDataSource

extension ItemDetailViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return viewState?.numOfPickerComponents ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case repeatPicker:
            return viewState?.repeatStateCount ?? 0
        case projectPicker:
            return viewState?.projectCount ?? 0
        default:
            assertionFailure("unhandled picker")
            return 0
        }
    }
}

// MARK: - UITextFieldDelegate

extension ItemDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        makeFirstResponder(nextResponderInArray)
        return false
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case dateTextField:
            textField.inputView = viewState?.date == nil ? simpleDatePicker : datePicker
            addCalendarButton()
        default:
            removeCalendarButton()
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case dateTextField:
            switch textField.inputView {
            case datePicker:
                guard let date = viewState?.date else { return }
                datePicker.setDate(date, animated: true)
            case simpleDatePicker:
                simpleDatePicker.selectRow(0, inComponent: 0, animated: true)
            default:
                assertionFailure("unhandled date picker")
            }
        case repeatsTextField:
            repeatPicker.selectRow(viewState?.repeatState?.rawValue ?? 0, inComponent: 0, animated: true)
        default:
            break
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch textField {
        case dateTextField: viewState?.date = nil
        case repeatsTextField: viewState?.repeatState = nil
        case projectTextField: viewState?.project = nil
        default: break
        }
        notifyStateUpdated()
        return true
    }
}

// MARK: - UITextViewDelegate

extension ItemDetailViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isEditable = false
    }

    func textViewDidChange(_ textView: UITextView) {
        viewState?.notes = textView.text
        notifyStateUpdated()
    }
}

// MARK: - SimpleDatePickerDelegate

extension ItemDetailViewController: SimpleDatePickerDelegate {
    func datePicker(_ picker: SimpleDatePicker, didSelectDate date: Date?) {
        viewState?.date = date
        notifyStateUpdated()
    }
}
