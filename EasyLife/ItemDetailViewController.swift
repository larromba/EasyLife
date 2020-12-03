import PPBadgeView
import UIKit

// sourcery: name = ItemDetailViewController
protocol ItemDetailViewControlling: ResponderSelection, Presentable, Mockable {
    var viewState: ItemDetailViewStating? { get set }

    func setDelegate(_ delegate: ItemDetailViewControllerDelegate)
}

protocol ItemDetailViewControllerDelegate: AnyObject {
    func viewControllerWillAppear(_ viewController: ItemDetailViewControlling)
    func viewController(_ viewController: ItemDetailViewControlling, performAction action: ItemDetailAction)
    func viewController(_ viewController: ItemDetailViewControlling, updatedState state: ItemDetailViewStating)
    func viewControllerWillDismiss(_ viewController: ItemDetailViewControlling)
}

// swiftlint:disable file_length
final class ItemDetailViewController: UIViewController, ItemDetailViewControlling {
    @IBOutlet private(set) weak var titleTextField: UITextField!
    @IBOutlet private(set) weak var dateTextField: UITextField!
    @IBOutlet private(set) weak var repeatsTextField: UITextField!
    @IBOutlet private(set) weak var projectTextField: UITextField!
    @IBOutlet private(set) weak var textView: UITextView!
    @IBOutlet private(set) weak var blockedButton: UIBarButtonItem!
    @IBOutlet private(set) weak var scrollView: UIScrollView!
    private(set) lazy var toolbar: UIToolbar = {
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
    private(set) lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dateTapped(_:)))
        tap.numberOfTapsRequired = 2
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        datePicker.addGestureRecognizer(tap)
        return datePicker
    }()
    private(set) lazy var simpleDatePicker = SimpleDatePicker(delegate: self)
    private(set) lazy var repeatPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    private(set) lazy var projectPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    private(set) var calendarButton: UIBarButtonItem?
    private(set) var blockedBadgeLabel: PPBadgeLabel?
    private lazy var textViewTapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesEnded = false
        return tapGesture
    }()
    private let keyboardNotification = KeyboardNotification()
    private weak var delegate: ItemDetailViewControllerDelegate?
    var responders: [UIResponder]!
    var viewState: ItemDetailViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardNotification.delegate = self
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
        setTextViewIsEditable(false)
        _ = viewState.map(bind)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.viewControllerWillAppear(self)
        keyboardNotification.setup()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            delegate?.viewControllerWillDismiss(self)
        }
        keyboardNotification.tearDown()
        view.endEditing(true)
    }

    func setDelegate(_ delegate: ItemDetailViewControllerDelegate) {
        self.delegate = delegate
    }

    // MARK: - private

    private func bind(_ viewState: ItemDetailViewStating) {
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
        repeatsTextField.text = viewState.repeatState.stringValue()
        projectTextField.text = viewState.project?.name
        projectTextField.isUserInteractionEnabled = viewState.isProjectTextFieldEnabled
        projectTextField.alpha = viewState.projectTextFieldAlpha
        blockedButton.isEnabled = viewState.isBlockedButtonEnabled
        blockedButton.pp.addBadge(number: viewState.blockedCount)
        blockedButton.pp.setBadgeLabel(attributes: { self.blockedBadgeLabel = $0 })
    }

    private func setTextViewIsEditable(_ isEditable: Bool) {
        if isEditable {
            textView.removeGestureRecognizer(textViewTapGesture)
        } else {
            textView.addGestureRecognizer(textViewTapGesture)
        }
        textView.isEditable = isEditable
    }

    private func makeFirstResponder(_ responder: UIResponder?) {
        if responder == textView { setTextViewIsEditable(true) }
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
            viewState?.date = nil
            notifyStateUpdated()
            dateTextField.inputView = simpleDatePicker
            simpleDatePicker.selectRow(0, inComponent: 0, animated: true)
        case simpleDatePicker:
            dateTextField.inputView = datePicker
            if let date = viewState?.date {
                datePicker.setDate(date, animated: true)
            }
        default:
            assertionFailure("unexpected input view")
        }
        dateTextField.reloadInputViews()
        toggleCalendarButton()
    }

    @IBAction private func textFieldChanged(_ sender: UITextField) {
        viewState?.name = sender.text
        notifyStateUpdated()
    }

    private func notifyStateUpdated() {
        guard let viewState = viewState else { return }
        delegate?.viewController(self, updatedState: viewState)
    }
}

// MARK: - KeyboardNotificationDelegate

extension ItemDetailViewController: KeyboardNotificationDelegate {
    func keyboardWithShow(height: CGFloat) {
        scrollView.contentInset.bottom = height
    }

    func keyboardWillHide() {
        scrollView.contentInset.bottom = 0
    }
}

// MARK: - UIPickerViewDelegate

extension ItemDetailViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case repeatPicker:
            return viewState?.repeatStatePickerItem(at: row).title
        case projectPicker:
            return viewState?.projectPickerItem(at: row).title
        default:
            assertionFailure("unhandled picker")
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case repeatPicker:
            guard let repeatState = viewState?.repeatStatePickerItem(at: row).object else { return }
            viewState?.repeatState = repeatState
        case projectPicker:
            guard let project = viewState?.projectPickerItem(at: row).object else { return }
            viewState?.project = project
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
        guard let viewState = viewState else { return false }
        switch textField {
        case dateTextField:
            switch viewState.datePickerType {
            case .simple: textField.inputView = simpleDatePicker
            case .normal: textField.inputView = datePicker
            }
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
            guard let row = viewState?.rowForRepeatState() else { return }
            repeatPicker.selectRow(row, inComponent: 0, animated: true)
        case projectTextField:
            guard let row = viewState?.rowForProject() else { return }
            projectPicker.selectRow(row, inComponent: 0, animated: true)
        default:
            break
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch textField {
        case dateTextField: viewState?.date = nil
        case repeatsTextField: viewState?.repeatState = .default
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
        setTextViewIsEditable(false)
    }

    func textViewDidChange(_ textView: UITextView) {
        viewState?.notes = textView.text
        notifyStateUpdated()
    }
}

// MARK: - SimpleDatePickerDelegate

extension ItemDetailViewController: SimpleDatePickerDelegate {
    func datePicker(_ picker: SimpleDatePicking, didSelectDate date: Date?) {
        viewState?.date = date
        notifyStateUpdated()
    }
}
