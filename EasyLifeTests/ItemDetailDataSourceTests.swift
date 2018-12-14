import CoreData
@testable import EasyLife
import XCTest

class ItemDetailDataSourceTests: XCTestCase {
    func testSave() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            override func save(context: NSManagedObjectContext, success: DataManager.Success?,
                               failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ItemDetailDataSource()
        let dataManager = MockDataManager()
        let item = MockTodoItem()

        // prepare
        dataSource.item = item
        dataSource.dataManager = dataManager

        // test
        dataSource.save()
        XCTAssertTrue(dataManager.didSave)
    }

    func testDelete() {
        // mocks
        class MockDataManager: DataManager {
            var didDelete = false
            var didSave = false

            override func delete<T>(_ entity: T, context: NSManagedObjectContext) where T: NSManagedObject {
                didDelete = true
            }
            override func save(context: NSManagedObjectContext, success: DataManager.Success?,
                               failure: DataManager.Failure?) {
                didSave = true
                success!()
            }
        }
        let dataSource = ItemDetailDataSource()
        let dataManager = MockDataManager()
        let item = MockTodoItem()

        // prepare
        dataSource.item = item
        dataSource.dataManager = dataManager

        // test
        dataSource.delete()
        XCTAssertNil(dataSource.item)
        XCTAssertFalse(dataSource.canSave)
        XCTAssertTrue(dataManager.didDelete)
        XCTAssertTrue(dataManager.didSave)
    }

    func testCreate() {
        // mocks
        class MockDataManager: DataManager {
            var didSave = false
            var didInsert = false
            override func insert<T>(entityClass: T.Type, context: NSManagedObjectContext, transient: Bool) -> T? where T: NSManagedObject {
                didInsert = true
                return super.insert(entityClass: entityClass, context: mainContext)
            }
        }
        let dataSource = ItemDetailDataSource()
        let dataManager = MockDataManager()

        // prepare
        dataSource.dataManager = dataManager

        // test
        dataSource.create()
        XCTAssertTrue(dataManager.didInsert)
    }
}
