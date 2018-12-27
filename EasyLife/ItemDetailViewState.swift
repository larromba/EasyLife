import Foundation
import CoreGraphics

protocol ItemDetailViewStating {
    var name: String? { get }
    var notes: String? { get }
    var minimumDate: Date? { get }
    var simpleDatePickerViewState: SimpleDatePickerViewStating { get }
    var date: Date? { get }
    var dateString: String? { get }
    var repeatState: RepeatState? { get }
    var project: Project? { get }
    var blockable: [BlockedItem] { get }
    var action: ItemDetailAction { get }
    var numOfPickerComponents: Int { get }
    var repeatStateCount: Int { get }
    var projectCount: Int { get }
    var isProjectTextFieldEnabled: Bool { get }
    var projectTextFieldAlpha: CGFloat { get }
    var isBlockedButtonEnabled: Bool { get }
    var blockedCount: Int { get }

    func repeatStatePickerComponent(at row: Int) -> RepeatStateComponentItem
    func projectPickerComponent(at row: Int) -> ProjectComponentItem
}

struct ItemDetailViewState: ItemDetailViewStating {
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        return dateFormatter
    }()

    var name: String?
    var notes: String?
    var minimumDate: Date? // TODO: ?
    let simpleDatePickerViewState: SimpleDatePickerViewStating = {
        return SimpleDatePickerViewState(date: Date(), rows: DateSegment.display)
    }()
    var date: Date?
    var dateString: String? {
        guard let date = date else { return nil }
        return dateFormatter.string(from: date)
    }
    var repeatState: RepeatState?
    var project: Project?
    let blockable: [BlockedItem]
    let action: ItemDetailAction
    var numOfPickerComponents: Int = 1
    var repeatStateCount: Int {
        return repeatStatePickerComponents.count
    }
    var projectCount: Int {
        return projectPickerComponents.count
    }
    var isProjectTextFieldEnabled: Bool {
        return projectCount > 0
    }
    var projectTextFieldAlpha: CGFloat {
        return projectCount > 0 ? 1.0 : 0.5
    }
    var isBlockedButtonEnabled: Bool {
        return !blockable.isEmpty
    }
    var blockedCount: Int {
        return blockable.filter { $0.isBlocked }.count
    }

    private var repeatStatePickerComponents: [RepeatStateComponentItem]
    private var projectPickerComponents: [ProjectComponentItem]

    init(item: TodoItem, items: [TodoItem], projects: [Project]) {
        name = item.name
        notes = item.notes
        repeatState = item.repeatState
        project = item.project
        blockable = items.map { return BlockedItem(item: $0, isBlocked: ($0.blocking?.contains(item) ?? false)) }
        action = (item.managedObjectContext == nil) ? .save : .delete
        repeatStatePickerComponents = RepeatState.display.map { RepeatStateComponentItem(object: $0) }
        projectPickerComponents = projects.map { ProjectComponentItem(object: $0) }
    }

    func repeatStatePickerComponent(at row: Int) -> RepeatStateComponentItem {
        return repeatStatePickerComponents[row]
    }

    func projectPickerComponent(at row: Int) -> ProjectComponentItem {
        return projectPickerComponents[row]
    }
}
