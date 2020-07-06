import UIKit

protocol SimpleDatePickerDelegate: AnyObject {
    func datePicker(_ picker: SimpleDatePicker, didSelectDate date: Date?)
}

// sourcery: name = SimpleDatePicker
protocol SimpleDatePickering: Mockable {
    var viewState: SimpleDatePickerViewStating? { get set }
}

final class SimpleDatePicker: UIPickerView, SimpleDatePickering {
    private weak var datePickerDelegate: SimpleDatePickerDelegate?
    var viewState: SimpleDatePickerViewStating? {
        didSet { _ = viewState.map(bind) }
    }

    init(delegate: SimpleDatePickerDelegate) {
        self.datePickerDelegate = delegate
        super.init(frame: CGRect.zero)
        self.delegate = self
        dataSource = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - private

    private func bind(_ viewState: SimpleDatePickerViewStating) {
        reloadAllComponents()
    }
}

// MARK: - UIPickerViewDelegate

extension SimpleDatePicker: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewState?.item(for: row).stringValue()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        datePickerDelegate?.datePicker(self, didSelectDate: viewState?.date(for: row))
    }
}

// MARK: - UIPickerViewDataSource

extension SimpleDatePicker: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return viewState?.numOfComponents ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewState?.rowCount ?? 0
    }
}
