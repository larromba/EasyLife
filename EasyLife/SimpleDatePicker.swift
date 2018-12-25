import UIKit

protocol SimpleDatePickerDelegate: AnyObject {
    func datePicker(_ picker: SimpleDatePicker, didSelectDate date: Date?)
}

// TODO: controller?
final class SimpleDatePicker: UIPickerView {
    var date: Date?
    var data: [DateSegment]
    weak var datePickerDelegate: SimpleDatePickerDelegate?

    init(delegate: SimpleDatePickerDelegate?, date: Date?, data: [DateSegment]) {
        self.date = date
        self.datePickerDelegate = delegate
        self.data = data
        super.init(frame: CGRect.zero)
        self.delegate = self
        dataSource = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SimpleDatePicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row].stringValue()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let date = date {
            datePickerDelegate?.datePicker(self, didSelectDate: data[row].increment(date: date))
        } else {
            datePickerDelegate?.datePicker(self, didSelectDate: nil)
        }
    }
}

extension SimpleDatePicker: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
}
