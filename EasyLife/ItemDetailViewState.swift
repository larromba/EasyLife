import Foundation

struct ItemDetailViewState {
    var name: String?
    var notes: String?
    var minimumDate: Date?
    var date: Date?  // dateFormatter.string(from: date) ?
    var dateString: String?
    var repeatState: RepeatState?  // repeatStateData = RepeatState.display
    var project: Project?
    var projects: [Project]?
    var repeatStateData: [RepeatState]
    var blockable: [BlockedItem]?
    var pickerComponents: [ItemDetailComponent: [AnyComponentItem<Any>]]
    var canSave: Bool
    var numOfPickerComponents: Int
}
