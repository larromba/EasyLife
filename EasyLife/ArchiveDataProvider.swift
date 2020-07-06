import Foundation

// sourcery: ArchiveDataProvider
protocol ArchiveDataProviding {
    var sections: [Character: [TodoItem]] { get }

    func setupWithItems(_ items: [TodoItem])
    func sections(for items: [TodoItem]) -> [Character: [TodoItem]]
    func sections(for term: String) -> [Character: [TodoItem]]
}

final class ArchiveDataProvider: ArchiveDataProviding {
    private(set) var sections = [Character: [TodoItem]]()

    func setupWithItems(_ items: [TodoItem]) {
        sections = sections(for: items)
    }

    func sections(for items: [TodoItem]) -> [Character: [TodoItem]] {
        var sections = [Character: [TodoItem]]()
        items.forEach {
            let section: Character
            if let name = $0.name, !name.isEmpty {
                section = Character(String(name[name.startIndex]).uppercased())
            } else {
                section = Character("-")
            }
            var items = sections[section] ?? [TodoItem]()
            items.append($0)
            sections[section] = items.sorted(by: { ($0.name ?? "") < ($1.name ?? "") })
        }
        return sections
    }

    func sections(for term: String) -> [Character: [TodoItem]] {
        guard !term.isEmpty else {
            return sections
        }
        var filteredSections = [Character: [TodoItem]]()
        sections.keys.forEach {
            if let result = sections[$0]?.filter({
                $0.name?.lowercased().range(of: term, options: .caseInsensitive) != nil
            }), !result.isEmpty {
                filteredSections[$0] = result
            } else {
                filteredSections.removeValue(forKey: $0)
            }
        }
        return filteredSections
    }
}
