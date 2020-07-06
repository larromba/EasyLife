import UIKit

typealias RepeatColorViewAnimation = (RepeatAnimation & ColorAnimation & ViewAnimation)

protocol RepeatAnimation: AnyObject {
    func stop()
}

protocol ColorAnimation: AnyObject {
    var alpha: CGFloat { get set }
}

protocol ViewAnimation: AnyObject {
    func start(in view: UIView)
}
