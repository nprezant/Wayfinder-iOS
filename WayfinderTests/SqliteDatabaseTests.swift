// Wayfinder

import XCTest
@testable import Wayfinder

class WayfinderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // TODO create database in memory
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInsertReflection() throws {
        // Create database in memory. No data should be loaded yet
        let db = try! SqliteDatabase.openInMemory()
        XCTAssert(db.reflections().isEmpty)
        
        // Insert reflection
        var r1 = Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "").reflection
        let insertedId = try! db.insert(reflection: r1)
        XCTAssertEqual(insertedId, 1)
        r1.id = insertedId
        
        // Verify inserted reflection
        let loadedReflections = db.reflections()
        XCTAssertEqual(loadedReflections.count, 1)
        XCTAssertEqual(loadedReflections[0], r1)
        
        // Insert another reflection
        var r2 = Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "My note").reflection
        let insertedId2 = try! db.insert(reflection: r2)
        XCTAssertEqual(insertedId2, 2)
        r2.id = insertedId2
        
        let loadedReflections2 = db.reflections()
        XCTAssertEqual(loadedReflections2.count, 2)
        XCTAssertEqual(loadedReflections2.sorted(by: {$0.id < $1.id}), [r1, r2])
    }
    
    func testDeleteReflection() throws {
        // Create database in memory. No data should be loaded yet
        let db = try! SqliteDatabase.openInMemory()
        XCTAssert(db.reflections().isEmpty)
        
        // Insert reflection
        var r1 = Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "").reflection
        let insertedId = try! db.insert(reflection: r1)
        XCTAssertEqual(insertedId, 1)
        r1.id = insertedId
        
        // Verify inserted reflection
        let loadedReflections = db.reflections()
        XCTAssertEqual(loadedReflections.count, 1)
        XCTAssertEqual(loadedReflections[0], r1)
        
        // Delete reflection
        try db.delete(reflectionsIds: [r1.id])
        
        // Verify reflection was deleted
        XCTAssert(db.reflections().isEmpty)
    }
    
    func testDeleteReflections() throws {
        // TODO implement
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
