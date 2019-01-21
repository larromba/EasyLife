import Foundation

public func assertionFailureIgnoreTests(_ message: String) {
    let isTesting = (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
    guard !isTesting else { return }
    assertionFailure(message)
}
