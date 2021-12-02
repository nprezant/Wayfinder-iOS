// Wayfinder

import XCTest
@testable import Wayfinder

class SqliteDatabaseTests: XCTestCase {
    
    var testData: [Reflection] = []

    override func setUpWithError() throws {
        // This method is called before the invocation of each test method in the class.
        testData = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note", axis: "Work").reflection,
        ]
    }

    override func tearDownWithError() throws {
        // This method is called after the invocation of each test method in the class.
        testData.removeAll()
    }
    
    func testOpenDatabase() throws {
        let tempPath = TestUtils.makeTempPath()
        let _ = try SqliteDatabase.open(at: tempPath)
        try FileManager.default.removeItem(at: tempPath)
    }
    
    func testOpenDatabaseInMemory() throws {
        let _ = try SqliteDatabase.openInMemory()
    }

    func testGetVersion() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        let version = db.version
        
        XCTAssertEqual(version, SqliteDatabase.latestVersion)
    }
    
    func testSetVersionDoesNotThrow() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        db.version = 2
    }
    
    func testSetVersionSetsProperly() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        db.version = 2
        
        let gotVersion = db.version
        
        XCTAssertEqual(gotVersion, 2)
    }
}
