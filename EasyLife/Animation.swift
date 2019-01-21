import UIKit

typealias RepeatColorViewAnimation = ViewAnimation & RepeatAnimation & ColorAnimation

protocol ViewAnimation: AnyObject {
    func start(in view: UIView)
}

protocol RepeatAnimation: AnyObject {
    func stop()
}

protocol ColorAnimation: AnyObject {
    var alpha: CGFloat { get set }
}
