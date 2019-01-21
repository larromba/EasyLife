import Foundation

struct BlockingContext<T: AnyObject> {
    let object: T
    var isBlocking: Bool
}
