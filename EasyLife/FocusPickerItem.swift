import Foundation

struct FocusPickerItem: PickerItem {
    var title: String? {
        object.displayValue()
    }
    var object: FocusTime
}
