//
//  ItemDetailViewController.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class ItemDetailViewController : UIViewController, ResponderSelection {
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var dateTextField: UITextField!
    @IBOutlet var repeatsTextField: UITextField!
    @IBOutlet var textView: UITextView!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var scrollView: UIScrollView!
    
    var dataManager: DataManager!
    var item: TodoItem?
    var dateFormatter: DateFormatter
    var responders: [UIResponder]!
   
    lazy var origContentSize: CGSize = {
        return self.scrollView.contentSize
    }()
    
    lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44))
        toolbar.barStyle = .default
        let prev = UIBarButtonItem(image: UIImage(named:"backward_arrow"), style: .plain, target: self, action: #selector(prevPressed(_:)))
        let next = UIBarButtonItem(image: UIImage(named:"forward_arrow"), style: .plain, target: self, action: #selector(nextPressed(_:)))
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spacer.width = 10.0
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(donePressed(_:)))
        toolbar.setItems([prev, spacer, next, flexSpace, done], animated: false)
        return toolbar
    }()

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = Date()
        datePicker.minuteInterval = 15
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        return datePicker
    }()
    
    lazy var repeatPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        return pickerView
    }()
    
    required init?(coder aDecoder: NSCoder) {
        dataManager = DataManager.shared
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm a"
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        responders = [
            titleTextField,
            dateTextField,
            repeatsTextField,
            textView
        ]
        
        repeatsTextField.inputView = repeatPickerView
        repeatsTextField.inputAccessoryView = toolbar
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = toolbar
        titleTextField.inputAccessoryView = toolbar
        textView.inputAccessoryView = toolbar
        textView.layer.cornerRadius = 5.0
        textView.layer.borderColor = UIColor(red: 205.0/255.0, green: 205.0/255.0, blue: 205.0/255.0, alpha: 1.0).cgColor
        textView.layer.borderWidth = 0.5
        textView.textContainerInset.left = 2.0
        textView.textContainerInset.right = 2.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
        loadItem(item)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let item = item {
            writeItem(item)
            dataManager.save()
        }
        tearDownNotifications()
    }
    
    // MARK: - private
    
    fileprivate func loadItem(_ item: TodoItem?) {
        guard let item = item else {
            titleTextField.text = nil
            textView.text = nil
            repeatsTextField.text = nil
            textView.text = nil
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePressed(_:)))
            return
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deletePressed(_:)))
        titleTextField.text = item.name
        if let date = item.date as? Date {
            dateTextField.text = dateFormatter.string(from: date)
        }
        repeatsTextField.text = item.repeatsState?.stringValue()
        textView.text = item.notes
    }
    
    fileprivate func writeItem(_ item: TodoItem) {
        item.name = titleTextField.text
        item.notes = textView.text
        if let dateText = dateTextField.text {
            item.date = dateFormatter.date(from: dateText) as NSDate?
        }
        item.repeats = Int16(repeatPickerView.selectedRow(inComponent: 0))
    }
    
    fileprivate func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    fileprivate func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: - action
    
    @IBAction fileprivate func savePressed(_ sender: UIBarButtonItem?) {
        guard let item = dataManager.insert(entityClass: TodoItem.self) else {
            return
        }
        writeItem(item)
        dataManager.save(success: { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction fileprivate func deletePressed(_ sender: UIBarButtonItem?) {
        guard let item = item else {
            return
        }
        dataManager.delete(item)
        dataManager.save(success: { [weak self] in
            _ = self?.navigationController?.popViewController(animated: true)
        })
    }
    
    @objc fileprivate func prevPressed(_ sender: UIBarButtonItem) {
        previous()
    }
    
    @objc fileprivate func nextPressed(_ sender: UIBarButtonItem?) {
        next()
    }
    
    @objc fileprivate func donePressed(_ sender: UIBarButtonItem) {
        view.endEditing(true)
    }
    
    @objc fileprivate func dateChanged(_ sender: UIDatePicker) {
        dateTextField.text = dateFormatter.string(from: sender.date)
    }
    
    @objc fileprivate func keyboardWillShow(_ notification: NSNotification) {
        guard let height = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        scrollView.contentSize.height = origContentSize.height + height.cgRectValue.height
    }
    
    @objc fileprivate func keyboardWillHide(_ notification: NSNotification) {
        scrollView.contentSize.height = origContentSize.height
    }
}

// MARK: - UIPickerViewDelegate

extension ItemDetailViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Repeat(rawValue: row)?.stringValue()
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        repeatsTextField.text = pickerView.delegate?.pickerView?(pickerView, titleForRow: row, forComponent: component)
    }
}

// MARK: - UIPickerViewDataSource

extension ItemDetailViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 5
    }
}

// MARK: - UITextFieldDelegate

extension ItemDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextPressed(nil)
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case dateTextField:
            if let text = dateTextField.text, let date = dateFormatter.date(from: text) {
                datePicker.setDate(date, animated: true)
            }
        case repeatsTextField:
            if let text = repeatsTextField.text, let row = Repeat(rawString: text)?.rawValue {
                repeatPickerView.selectRow(Int(row), inComponent: 0, animated: true)
            }
        default:
            break
        }
    }
}
