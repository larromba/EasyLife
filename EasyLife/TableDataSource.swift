import Foundation

protocol TableDataSourceDelegate: AnyObject {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T)
}

protocol TableDataSource {
    associatedtype Object

    var delegate: TableDataSourceDelegate? { get set }

    func load()
    func title(for section: Int) -> String?
    func item(at indexPath: IndexPath) -> Object?
    func section(at index: Int) -> [Object]?
}

extension TableDataSource {
    func title(for section: Int) -> String? { return nil }
    func section(at index: Int) -> [Object]? { return nil }
}
