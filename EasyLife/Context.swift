import Foundation

struct Context<T: AnyObject> {
    let object: T
}

struct ValueContext<T> {
    var object: T
}
