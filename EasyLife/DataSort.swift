import Foundation

final class DataSort<T> {
    let sortDescriptor: [NSSortDescriptor]?
    let sortFunction: ((T, T) -> Bool)?

    init(sortDescriptor: [NSSortDescriptor]) {
        self.sortDescriptor = sortDescriptor
        sortFunction = nil
    }

    init(sortFunction: @escaping (T, T) -> Bool) {
        self.sortFunction = sortFunction
        sortDescriptor = nil
    }
}
