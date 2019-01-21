import Foundation

extension Bundle {
    static func appVersion() -> String {
        return "v\(main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")"
    }

    static var safeMain: Bundle {
        return Bundle(identifier: "com.pinkchicken.easylife")!
    }
}
