import UIKit

// TODO: this?
// swiftlint:disable identifier_name
extension UIColor {
    class var appleGrey: UIColor {
        return r(205.0, g: 205.0, b: 205.0)
    }

    class var lightGreen: UIColor {
        return r(116.0, g: 230.0, b: 131.0)
    }

    class var lightRed: UIColor {
        return r(230.0, g: 98.0, b: 88.0)
    }

    class var priority1: UIColor {
        return r(225.0, g: 105.0, b: 109.0)
    }

    class var priority2: UIColor {
        return r(242.0, g: 165.0, b: 65.0)
    }

    class var priority3: UIColor {
        return r(243.0, g: 202.0, b: 64.0)
    }

    class var priority4: UIColor {
        return r(210.0, g: 224.0, b: 154.0)
    }

    class var priority5: UIColor {
        return r(218.0, g: 214.0, b: 214.0)
    }

    // MARK: - private

    fileprivate class func r(_ r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1.0)
    }
}
