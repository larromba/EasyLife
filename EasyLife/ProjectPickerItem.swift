import Foundation

struct ProjectPickerItem: PickerItem {
    var title: String? {
        return object.name
    }
    let object: Project
}
