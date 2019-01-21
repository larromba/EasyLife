import Foundation

func performAfterDelay(_ delay: Double, closure: @escaping (() -> Void)) {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
