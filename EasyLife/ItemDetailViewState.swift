import CoreGraphics
import Foundation

protocol ItemDetailViewStating {
    var isNew: Bool { get }
    var name: String? { get set }
    var notes: String? { get set }
    var minimumDate: Date? { get }
    var simpleDatePickerViewState: SimpleDatePickerViewStating { get }
    var date: Date? { get set }
    var dateString: String? { get }
    var datePickerType: ItemDetailDatePickerType { get }
    var repeatState: RepeatState { get set }
    var project: Project? { get set }
    var leftButton: ItemDetailLeftButton { get }
    var rightButton: ItemDetailRightButton { get }
    var numOfPickerComponents: Int { get }
    var repeatStateCount: Int { get }
    var projectCount: Int { get }
    var isProjectTextFieldEnabled: Bool { get }
    var projectTextFieldAlpha: CGFloat { get }
    var isBlockedButtonEnabled: Bool { get }
    var blockedCount: Int { get }

    func repeatStatePickerComponent(at row: Int) -> RepeatStateComponentItem
    func projectPickerComponent(at row: Int) -> ProjectComponentItem

    func copy(item: TodoItem, items: [TodoItem], projects: [Project]) -> ItemDetailViewStating
}

enum ItemDetailDatePickerType {
    case simple
    case normal
}

struct ItemDetailViewState: ItemDetailViewStating {
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE dd/MM/yyyy"
        return dateFormatter
    }()

    var isNew: Bool
    var name: String?
    var notes: String?
    var minimumDate: Date?
    let simpleDatePickerViewState: SimpleDatePickerViewStating = {
        return SimpleDatePickerViewState(date: Date(), rows: DateSegment.display)
    }()
    var date: Date?
    var dateString: String? {
        guard let date = date else { return nil }
        return dateFormatter.string(from: date)
    }
    var datePickerType: ItemDetailDatePickerType {
        return date == nil ? .simple : .normal
    }
    var repeatState: RepeatState
    var project: Project?
    let leftButton: ItemDetailLeftButton
    let rightButton: ItemDetailRightButton
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
    let isBlockedButtonEnabled: Bool
    let blockedCount: Int

    private var repeatStatePickerComponents: [RepeatStateComponentItem]
    private var projectPickerComponents: [ProjectComponentItem]

    init(item: TodoItem, isNew: Bool, items: [TodoItem], projects: [Project]) {
        self.isNew = isNew
        name = item.name
        notes = item.notes
        date = item.date
        minimumDate = Date().earliest
        repeatState = item.repeatState
        project = item.project
        isBlockedButtonEnabled = !items.isEmpty
        blockedCount = items.filter { $0.blocking?.contains(item) ?? false }.count
        rightButton = isNew ? .save : .delete
        leftButton = isNew ? .cancel : .back
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

extension ItemDetailViewState {
    func copy(item: TodoItem, items: [TodoItem], projects: [Project]) -> ItemDetailViewStating {
        return ItemDetailViewState(item: item, isNew: isNew, items: items, projects: projects)
    }
}
