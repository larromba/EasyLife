import CoreGraphics
import Foundation

struct ArchiveViewState {
    private let unknownSection = Character("-")

    let sections: [Character: [TodoItem]]
    let searchSections: [Character: [TodoItem]]?
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

    func title(for section: Int) -> String? {
        guard let section = key(at: section) else {
            return nil
        }
        return String(section)
    }

    func item(at indexPath: IndexPath) -> TodoItem? {
        guard let key = key(at: indexPath.section), let items = sections[key],
            indexPath.row >= indexPath.startIndex, indexPath.row < items.endIndex else {
                return nil
        }
        return items[indexPath.row]
    }

    func section(at index: Int) -> [TodoItem]? {
        guard let key = key(at: index) else {
            return nil
        }
        return sections[key]
    }

    // MARK: - private

    private func key(at index: Int) -> Character? {
        let keys = Array(sections.keys).sorted(by: { $0 < $1 })
        guard index >= keys.startIndex, index < keys.endIndex else {
            return nil
        }
        return keys[index]
    }
}

extension ArchiveViewState {
    func copy(text: String?) -> ArchiveViewState {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(sections: [Character: [TodoItem]]) -> ArchiveViewState {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(searchSections: [Character: [TodoItem]]?) -> ArchiveViewState {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }

    func copy(sections: [Character: [TodoItem]], searchSections: [Character: [TodoItem]]?) -> ArchiveViewState {
        return ArchiveViewState(sections: sections, searchSections: searchSections, text: text)
    }
}
