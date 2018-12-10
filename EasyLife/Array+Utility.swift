import Foundation

extension Array {
    // O(*2n*)
    mutating func replace(_ newElement: Element, at i: Int) {
        remove(at: i)
        insert(newElement, at: i)
    }
}
