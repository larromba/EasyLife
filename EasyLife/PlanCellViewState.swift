import UIKit

protocol PlanCellViewStating {
    var iconImage: UIImage? { get }
    var isIconHidden: Bool { get }
    var infoText: String { get }
    var infoColor: UIColor { get }
    var isInfoLabelHidden: Bool { get }
    var titleText: String { get }
    var titleColor: UIColor { get }
    var notesText: String { get }
    var notesColor: UIColor { get }
    var isNotesLabelHidden: Bool { get }
    var tagViewAlpha: CGFloat { get }
    var tagViewState: TagViewStating { get }
    var blockedIndicatorViewState: BlockedIndicatorViewStating { get }
}

struct PlanCellViewState: PlanCellViewStating {
    private enum IconType {
        case noDate
        case recurring
        case none
    }

    let iconImage: UIImage?
    let isIconHidden: Bool
    let infoText: String
    let infoColor: UIColor
    let isInfoLabelHidden: Bool
    let titleText: String
    let titleColor: UIColor
    let notesText: String
    let notesColor: UIColor
    let isNotesLabelHidden: Bool
    let tagViewAlpha: CGFloat
    let tagViewState: TagViewStating
    let blockedIndicatorViewState: BlockedIndicatorViewStating

    init(item: TodoItem, section: PlanSection) {
        iconImage = type(of: self).iconImage(for: item)
        isIconHidden = type(of: self).isIconHidden(for: item)
        titleText = type(of: self).titleText(for: item)
        titleColor = type(of: self).titleColor(for: item, section: section)
        infoColor = type(of: self).textColor(for: section)
        notesColor = type(of: self).textColor(for: section)
        tagViewAlpha = type(of: self).tagViewAlpha(for: section)
        isInfoLabelHidden = type(of: self).isInfoLabelHidden(for: section)
        infoText = type(of: self).infoText(for: item)
        tagViewState = item.project.map { TagViewState(project: $0) } ?? TagViewState()
        blockedIndicatorViewState = type(of: self).blockedIndicatorViewState(for: item)
        notesText = item.notes ?? ""
        isNotesLabelHidden = type(of: self).isNotesLabelHidden(for: item)
    }

    static func iconImage(for item: TodoItem) -> UIImage? {
        switch iconType(for: item) {
        case .none: return nil
        case .noDate: return Asset.Assets.nodate.image
        case .recurring: return Asset.Assets.recurring.image
        }
    }

    static func isIconHidden(for item: TodoItem) -> Bool {
        switch iconType(for: item) {
        case .none: return true
        case .noDate: return false
        case .recurring: return false
        }
    }

    static func titleText(for item: TodoItem) -> String {
        if let name = item.name, !name.isEmpty {
            return name
        } else {
            return L10n.todoItemNoName
        }
    }

    static func titleColor(for item: TodoItem, section: PlanSection) -> UIColor {
        if let name = item.name, !name.isEmpty {
            return textColor(for: section)
        } else {
            return Asset.Colors.grey.color
        }
    }

    static func textColor(for section: PlanSection) -> UIColor {
        switch section {
        case .missed: return Asset.Colors.red.color
        case .today: return .black
        case .later: return Asset.Colors.grey.color
        }
    }

    static func tagViewAlpha(for section: PlanSection) -> CGFloat {
        switch section {
        case .missed: return 1.0
        case .today: return 1.0
        case .later: return 0.5
        }
    }

    static func isInfoLabelHidden(for section: PlanSection) -> Bool {
        switch section {
        case .missed: return true
        case .today: return true
        case .later: return false
        }
    }

    static func infoText(for item: TodoItem) -> String {
        if let date = item.date {
            let timeInterval = Date().earliest.timeIntervalSince(date)
            return DateComponentsFormatter.timeIntervalToString(timeInterval) ?? ""
        } else {
            return ""
        }
    }

    // swiftlint:disable empty_count (sets dont have isEmpty)
    static func blockedIndicatorViewState(for item: TodoItem) -> BlockedIndicatorViewStating {
        if let blockedBy = item.blockedBy, let blocking = item.blocking, blockedBy.count > 0 && blocking.count > 0 {
            return BlockedIndicatorViewState(state: .both)
        } else if let blockedBy = item.blockedBy, blockedBy.count > 0 {
            return BlockedIndicatorViewState(state: .blocked)
        } else if let blocking = item.blocking, blocking.count > 0 {
            return BlockedIndicatorViewState(state: .blocking)
        } else {
            return BlockedIndicatorViewState(state: .none)
        }
    }

    static func isNotesLabelHidden(for item: TodoItem) -> Bool {
        if let notes = item.notes, !notes.isEmpty {
            return false
        } else {
            return true
        }
    }

    // MARK: - private

    private static func iconType(for item: TodoItem) -> IconType {
        if item.date == nil {
            return .noDate
        } else if let repeatState = item.repeatState, repeatState != .none {
            return .recurring
        } else {
            return .none
        }
    }
}
