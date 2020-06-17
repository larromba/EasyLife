import Foundation
import Logging

// swiftlint:disable identifier_name
var __isSnapshot: Bool {
    return UserDefaults.standard.string(forKey: "FASTLANE_SNAPSHOT") != nil
}

func assertionFailureIgnoreTests(_ message: String) {
    let isTesting = (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
    guard !isTesting else {
        logError(message)
        return
    }
    assertionFailure(message)
}
