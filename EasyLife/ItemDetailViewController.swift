import UIKit
import PPBadgeView

class ItemDetailViewController: UIViewController, ResponderSelection {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var repeatsTextField: UITextField!
    @IBOutlet weak var projectTextField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var blockedButton: UIBarButtonItem!
    @IBOutlet weak var scrollView: UIScrollView!

    var responders: [UIResponder]!
    var dataSource: ItemDetailDataSource
    var calendarButton: UIBarButtonItem?
    private weak var blockedViewController: BlockedViewController?

    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        toolbar.barStyle = .default
        let prev = UIBarButtonItem(image: UIImage(named: "backward_arrow"), style: .plain, target: self, action: #selector(prevPressed(_:)))
        let next = UIBarButtonItem(image: UIImage(named: "forward_arrow"), style: .plain, target: self, action: #selector(nextPressed(_:)))
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 10.0
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed(_:)))
        toolbar.setItems([prev, spacer, next, spacer, flexSpace, spacer, done], animated: false)
        return toolbar
    }()

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = self.dataSource.now
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dateTapped(_:)))
        tap.numberOfTapsRequired = 2
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        datePicker.addGestureRecognizer(tap)
        return datePicker
    }()

    lazy var simpleDatePicker: SimpleDatePicker = {
        let datePicker = SimpleDatePicker(delegate: self, date: self.dataSource.now, data: DateSegment.display)
        return datePicker
    }()

    lazy var repeatPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()

    lazy var projectPicker: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()

    required init?(coder aDecoder: NSCoder) {
        dataSource = ItemDetailDataSource()
        super.init(coder: aDecoder)
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
        dateTextField.readonly = true
        titleTextField.inputAccessoryView = toolbar
        titleTextField.readonly = true
        textView.inputAccessoryView = toolbar
        textView.applyTextFieldStyle()
        textView.dataDetectorTypes = .all
        textView.isEditable = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(textViewTapped(_:)))
        tap.numberOfTapsRequired = 1
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        textView.addGestureRecognizer(tap)

        if dataSource.canSave {
            setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePressed(_:))))
        } else {
            setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deletePressed(_:))))
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
        dataSource.delegate = self
        if let blockedViewController = blockedViewController {
            dataSource.blockable = blockedViewController.dataSource.data
        }
        dataSource.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParentViewController {
            dataSource.save()
        }
        tearDownNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? BlockedViewController {
            blockedViewController = vc
            vc.dataSource.data = dataSource.blockable
        }
    }

    // MARK: - private

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
    }

    private func setRightBarButtonItem(_ item: UIBarButtonItem) {
        saveButton = item
        navigationItem.rightBarButtonItem = item
    }

    fileprivate func makeFirstResponder(_ responder: UIResponder?) {
        if responder == textView {
            textView.isEditable = true
        }
        responder?.becomeFirstResponder()
    }

    private func addCalendarTypeButton() {
        if let item = toolbar.items?[4], item != calendarButton {
            if dateTextField.inputView == datePicker {
                calendarButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(calendarButtonPressed(_:)))
            } else if dateTextField.inputView == simpleDatePicker {
                calendarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(calendarButtonPressed(_:)))
            }
            toolbar.items?.insert(calendarButton!, at: 4)
        }
    }

    private func removeCalendarTypeButton() {
        if let calendarButton = calendarButton, let index = toolbar.items?.index(of: calendarButton) {
            toolbar.items?.remove(at: index)
        }
    }

    // MARK: - action

    @IBAction private func savePressed(_ sender: UIBarButtonItem?) {
        dataSource.create()
        dataSource.save()
    }

    @IBAction private func deletePressed(_ sender: UIBarButtonItem?) {
        dataSource.delete()
    }

    @objc private func prevPressed(_ sender: UIBarButtonItem) {
        makeFirstResponder(previousResponderInArray)
    }

    @objc private func nextPressed(_ sender: UIBarButtonItem) {
        makeFirstResponder(nextResponderInArray)
    }

    @objc private func donePressed(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        dataSource.date = sender.date as Date?
    }

    @objc private func dateTapped(_ sender: UIDatePicker) {
        dataSource.date = sender.date as Date?
    }

    @objc private func textViewTapped(_ sender: UIDatePicker) {
        makeFirstResponder(textView)
    }

    @objc private func calendarButtonPressed(_ sender: UIBarButtonItem) {
        if dateTextField.inputView == datePicker {
            dateTextField.inputView = simpleDatePicker
        } else if dateTextField.inputView == simpleDatePicker {
            dateTextField.inputView = datePicker
        }
        dateTextField.reloadInputViews()
        removeCalendarTypeButton()
        addCalendarTypeButton()
    }

    @IBAction private func textFieldChanged(_ sender: UITextField) {
        dataSource.name = sender.text
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let height = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        scrollView.contentInset.bottom = height.cgRectValue.height
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }
}

// MARK: - UIPickerViewDelegate

extension ItemDetailViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == repeatPicker {
            return dataSource.repeatStateData[row].stringValue()
        } else if pickerView == projectPicker {
            return dataSource.projects?[row].name
        } else {
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == repeatPicker {
            dataSource.repeatState = dataSource.repeatStateData[row]
        } else if pickerView == projectPicker {
            dataSource.project = dataSource.projects?[row]
        }
    }
}

// MARK: - UIPickerViewDataSource

extension ItemDetailViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == repeatPicker {
            return dataSource.repeatStateData.count
        } else if pickerView == projectPicker {
            return dataSource.projects?.count ?? 0
        } else {
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
            if dataSource.date != nil {
                textField.inputView = datePicker
            } else {
                textField.inputView = simpleDatePicker
            }
            addCalendarTypeButton()
        default:
            removeCalendarTypeButton()
            break
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case dateTextField:
            if textField.inputView == datePicker, let date = dataSource.date {
                datePicker.setDate(date, animated: true)
            } else if textField.inputView == simpleDatePicker {
                simpleDatePicker.selectRow(0, inComponent: 0, animated: true)
            }
        case repeatsTextField:
            if let repeatState = dataSource.repeatState {
                repeatPicker.selectRow(repeatState.rawValue, inComponent: 0, animated: true)
            } else {
                repeatPicker.selectRow(0, inComponent: 0, animated: true)
            }
        default:
            break
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch textField {
        case dateTextField:
            dataSource.date = nil
        case repeatsTextField:
            dataSource.repeatState = nil
        case projectTextField:
            dataSource.project = nil
        default:
            break
        }
        return true
    }
}

// MARK: - UITextViewDelegate

extension ItemDetailViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.isEditable = false
    }

    func textViewDidChange(_ textView: UITextView) {
        dataSource.notes = textView.text
    }
}

// MARK: - SimpleDatePickerDelegate

extension ItemDetailViewController: SimpleDatePickerDelegate {
    func datePicker(_ picker: SimpleDatePicker, didSelectDate date: Date?) {
        dataSource.date = date
    }
}

// MARK: - ItemDetailDelegate

extension ItemDetailViewController: ItemDetailDelegate {
    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedName name: String?) {
        titleTextField.text = name
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedNotes notes: String?) {
        textView.text = notes
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedDate date: String?) {
        dateTextField.text = date
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedRepeatState state: RepeatState?) {
        if let state = state {
            repeatsTextField.text = state.stringValue()
        } else {
            repeatsTextField.text = nil
        }
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedProject project: Project?) {
        projectTextField.text = project?.name
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedProjects projects: [Project]?) {
        projectTextField.isUserInteractionEnabled = (projects?.count ?? 0 > 0)
        projectTextField.alpha = (projects?.count ?? 0 > 0) ? 1.0 : 0.5
    }

    func itemDetailDataSource(_ delegate: ItemDetailDataSource, updatedBlockable blockable: [BlockedItem]?) {
        blockedButton.isEnabled = (blockable?.count ?? 0) > 0
        blockedButton.pp.addBadge(number: blockable?.filter({ $0.isBlocked }).count ?? 0)
    }

    func itemDetailDataSourceDidDelete(_ delegate: ItemDetailDataSource) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    func itemDetailDataSourceDidSave(_ delegate: ItemDetailDataSource) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
