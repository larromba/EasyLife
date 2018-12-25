import UIKit

protocol ArchiveViewStating {
    var sections: [Character: [TodoItem]] { get }
    var numOfSections: Int { get }
    var totalItems: Int { get }
    var isEmpty: Bool { get }
    var isSearching: Bool { get }
    var rowHeight: CGFloat { get }
    var undoTitle: String { get }
    var undoBackgroundColor: UIColor { get }
    var text: String? { get }

    func title(for section: Int) -> String?
    func item(at indexPath: IndexPath) -> TodoItem?
    func cellViewState(at indexPath: IndexPath) -> ArchiveCellViewStating?
    func section(at index: Int) -> [TodoItem]?

    func copy(text: String?) -> ArchiveViewStating
    func copy(sections: [Character: [TodoItem]]) -> ArchiveViewStating
    func copy(searchSections: [Character: [TodoItem]]?) -> ArchiveViewStating
    func copy(sections: [Character: [TodoItem]], searchSections: [Character: [TodoItem]]?) -> ArchiveViewStating
}

struct ArchiveViewState: ArchiveViewStating {
    private let unknownSection = Character("-")
    private let searchSections: [Character: [TodoItem]]?

    let sections: [Character: [TodoItem]]
    var numOfSections: Int {
        return sections.keys.count
    }
    var totalItems: Int {
        return sections.reduce(0, { $0 + $1.value.count })
    }
    var isEmpty: Bool {
        return totalItems == 0
    }
    var isSearching: Bool {
        return searchSections != nil
    }
    let rowHeight: CGFloat = 50.0
    let undoTitle = L10n.archiveItemUndoOption
    let undoBackgroundColor = Asset.Colors.grey.color
    let text: String?

    init(sections: [Character: [TodoItem]], searchSections: [Character: [TodoItem]]?, text: String?) {
        self.sections = sections
        self.searchSections = searchSections
        self.text = text
    }

    func title(for section: Int) -> String? {
        guard let section = key(at: section) else { return nil }
        return String(section)
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        guard let key = key(at: indexPath.section), let items = sections[key],
            indexPath.row >= indexPath.startIndex, indexPath.row < items.endIndex else { return nil }
        return items[indexPath.row]
    }

    func cellViewState(at indexPath: IndexPath) -> ArchiveCellViewStating? {
        return item(at: indexPath).map { ArchiveCellViewState(item: $0) }
    }

    func section(at index: Int) -> [TodoItem]? {
        guard let key = key(at: index) else { return nil }
        return sections[key]
    }

    // MARK: - private

    private func key(at index: Int) -> Character? {
        let keys = Array(sections.keys).sorted(by: { $0 < $1 })
        guard index >= keys.startIndex, index < keys.endIndex else { return nil }
        return keys[index]
    }
}

extension ArchiveViewState {
    func copy(text: String?) -> ArchiveViewStating {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(sections: [Character: [TodoItem]]) -> ArchiveViewStating {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(searchSections: [Character: [TodoItem]]?) -> ArchiveViewStating {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(sections: [Character: [TodoItem]], searchSections: [Character: [TodoItem]]?) -> ArchiveViewStating {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }
}
