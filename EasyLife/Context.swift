import Foundation

struct ObjectContext<T: AnyObject> {
    let object: T
}

struct ValueContext<T> {
    var value: T
}
