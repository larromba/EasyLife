import Foundation

extension Bundle {
    class func appVersion() -> String {
        return "v\(main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")"
    }

    class var safeMain: Bundle {
        return Bundle(identifier: "com.pinkchicken.easylife")!
    }
}
