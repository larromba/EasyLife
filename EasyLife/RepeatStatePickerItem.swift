import Foundation

struct RepeatStatePickerItem: PickerItem {
    var title: String? {
        return object.stringValue()
    }
    let object: RepeatState
}
