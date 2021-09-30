// WayfinderTests

import XCTest
@testable import Wayfinder

class ReflectionTableTests: XCTestCase {
    
    var testData: [Reflection] = []

    override func setUpWithError() throws {
        testData = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note").reflection,
        ]
    }

    override func tearDownWithError() throws {
        testData.removeAll()
    }

    func testInsertReflection() throws {
        // Create database in memory. No data should be loaded yet
        let db = try! SqliteDatabase.openInMemory()
        XCTAssert(db.fetchReflections().isEmpty)
        
        // Insert reflection
        let insertedId = try! db.insert(reflection: testData[0])
        XCTAssertEqual(insertedId, 1)
        testData[0].id = insertedId
        
        // Verify inserted reflection
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections.count, 1)
        XCTAssertEqual(loadedReflections[0], testData[0])
        
        // Insert another reflection
        let insertedId2 = try! db.insert(reflection: testData[1])
        XCTAssertEqual(insertedId2, 2)
        testData[1].id = insertedId2
        
        let loadedReflections2 = db.fetchReflections()
        XCTAssertEqual(loadedReflections2.count, 2)
        XCTAssertEqual(loadedReflections2.sorted(by: {$0.id < $1.id}), [testData[0], testData[1]])
    }
    
    func testDeleteReflection() throws {
        // Create database in memory. No data should be loaded yet
        let db = try! SqliteDatabase.openInMemory()
        XCTAssert(db.fetchReflections().isEmpty)
        
        // Insert reflection
        let insertedId = try! db.insert(reflection: testData[0])
        XCTAssertEqual(insertedId, 1)
        testData[0].id = insertedId
        
        // Verify inserted reflection
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections.count, 1)
        XCTAssertEqual(loadedReflections[0], testData[0])
        
        // Delete reflection
        try db.delete(reflectionsIds: [testData[0].id])
        
        // Verify reflection was deleted
        XCTAssert(db.fetchReflections().isEmpty)
    }
    
    func testDeleteFirstReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        // Remove the first entry
        try! db.delete(reflectionsIds: [testData.first!.id])
        
        // Update test data to match
        testData.remove(at: 0)
        
        // Verify entry was removed
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections, testData)
    }
    
    func testDeleteLastReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        // Remove the first entry
        try! db.delete(reflectionsIds: [testData.last!.id])
        
        // Update test data to match
        testData.remove(at: testData.count - 1)
        
        // Verify entry was removed
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections, testData)
    }
    
    func testDeleteOneOfManyReflections() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        // Remove the second entry
        try! db.delete(reflectionsIds: [testData[1].id])
        
        // Update test data to match
        testData.remove(at: 1)
        
        // Verify entry was removed
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections, testData)
    }
    
    func testDeleteManyReflections() throws {
        let db = try! TestUtils.makeDatabase(with: &testData)
        
        // Setup values to remove (first and third entity)
        let toRemove = [0, 2]
        let idsToRemove = toRemove.map{testData[$0].id}
        
        // Remove from database
        for id in idsToRemove {
            try! db.delete(reflectionsIds: [id])
        }
        
        // Remove from test data
        testData.removeAll(where: {idsToRemove.contains($0.id)})
        
        // Verify entry was removed
        let loadedReflections = db.fetchReflections()
        XCTAssertEqual(loadedReflections, testData)
    }

}
