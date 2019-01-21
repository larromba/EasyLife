import XCTest
import CoreData
@testable import EasyLife

final class DataTests: XCTestCase {
    func testMigrations() {
        // mocks
        let bundle = Bundle(for: DataTests.self)
        do {
            // tests
            var url = bundle.url(forResource: "EasyLife", withExtension: "sqlite")
            try _ = NSPersistentContainer.inMemory(at: url)

            url = bundle.url(forResource: "EasyLife 1.3.0", withExtension: "sqlite")
            try _ = NSPersistentContainer.inMemory(at: url)

            url = bundle.url(forResource: "EasyLife 1.5.0", withExtension: "sqlite")
            try _ = NSPersistentContainer.inMemory(at: url)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
