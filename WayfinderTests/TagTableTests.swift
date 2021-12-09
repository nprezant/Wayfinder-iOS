// WayfinderTests

import XCTest
@testable import Wayfinder

class TagTableTests: XCTestCase {
    
    var testDataNoTags: [Reflection] = []
    var testDataWithTags: [Reflection] = []

    override func setUpWithError() throws {
        testDataNoTags = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note", axis: "Work").reflection,
        ]
        testDataWithTags = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work", tags: ["tagShared", "tag1.0", "tag1.1"]).reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note", axis: "Work", tags: ["tag2.0", "tagShared"]).reflection,
        ]
    }

    override func tearDownWithError() throws {
        testDataNoTags.removeAll()
        testDataWithTags.removeAll()
    }
    
    func testFetchAllUniqueTagsWhenNone() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = try db.fetchUniqueTagNames()
        let expectedTags: [String] = []
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchAllUniqueTags() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataWithTags)
        let dbTags = try db.fetchUniqueTagNames()
        let expectedTags: [String] = ["tagShared", "tag1.0", "tag1.1", "tag2.0"]
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchTagsForReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataWithTags)
        let dbTags = try db.fetchTags(for: 1)
        let expectedTags: [String] = ["tagShared", "tag1.0", "tag1.1"]
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchTagsForReflectionNoMatch() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = try db.fetchTags(for: 1000)
        let expectedTags: [String] = []
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testInsertTagForReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let tagsToInsert: [String] = ["insertedTag"]
        try db.insertTags(for: testDataNoTags[0].id, tags: tagsToInsert)
        
        let allDbTags = try db.fetchUniqueTagNames()
        XCTAssertEqual(allDbTags, tagsToInsert)
        
        let thisReflectionTags = try db.fetchTags(for: testDataNoTags[0].id)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        let otherReflectionTags = try db.fetchTags(for: testDataNoTags[1].id)
        XCTAssertEqual(otherReflectionTags, [])
    }
    
    func testInsertTagForReflectionWithSpaces() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let tagsToInsert: [String] = ["inserted tag"]
        try db.insertTags(for: testDataNoTags[0].id, tags: tagsToInsert)
        
        let allDbTags = try db.fetchUniqueTagNames()
        XCTAssertEqual(allDbTags, tagsToInsert)
        
        let thisReflectionTags = try db.fetchTags(for: testDataNoTags[0].id)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        let otherReflectionTags = try db.fetchTags(for: testDataNoTags[1].id)
        XCTAssertEqual(otherReflectionTags, [])
    }
    
    func testInsertTagsForReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let tagsToInsert: [String] = ["insertedTag", "insertedTag2", "insertedTag3"]
        try db.insertTags(for: testDataNoTags[0].id, tags: tagsToInsert)
        
        let allDbTags = try db.fetchUniqueTagNames()
        XCTAssertEqual(allDbTags, tagsToInsert)
        
        let thisReflectionTags = try db.fetchTags(for: testDataNoTags[0].id)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        let otherReflectionTags = try db.fetchTags(for: testDataNoTags[1].id)
        XCTAssertEqual(otherReflectionTags, [])
    }
    
    func testDeleteTagFromReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let reflectionId = testDataNoTags[0].id
        
        let tagsToInsert: [String] = ["insertedTag", "insertedTag2", "insertedTag3"]
        try db.insertTags(for: reflectionId, tags: tagsToInsert)
        
        var thisReflectionTags = try db.fetchTags(for: reflectionId)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        try db.deleteTags(for: reflectionId, tags: Array(tagsToInsert[0...1]))
        
        thisReflectionTags = try db.fetchTags(for: reflectionId)
        XCTAssertEqual(thisReflectionTags, Array(tagsToInsert[2...]))
    }
    
    func testDeleteReflectionCascadesToTags() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let reflectionId = testDataNoTags[0].id
        
        let tagsToInsert: [String] = ["insertedTag", "insertedTag2", "insertedTag3"]
        try db.insertTags(for: reflectionId, tags: tagsToInsert)
        
        var thisReflectionTags = try db.fetchTags(for: reflectionId)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        try db.delete(reflectionsIds: [reflectionId])
        
        thisReflectionTags = try db.fetchTags(for: reflectionId)
        XCTAssertEqual(thisReflectionTags, [])
    }
    
    func testUpdateReflectionCascadesToTags() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        
        let reflectionId = testDataNoTags[0].id
        
        let tagsToInsert: [String] = ["insertedTag", "insertedTag2", "insertedTag3"]
        try db.insertTags(for: reflectionId, tags: tagsToInsert)
        
        var thisReflectionTags = try db.fetchTags(for: reflectionId)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
        
        try db.execute(sql: "UPDATE reflection SET id = 100 WHERE name = 'First Reflection';")
        
        thisReflectionTags = try db.fetchTags(for: 100)
        XCTAssertEqual(thisReflectionTags, tagsToInsert)
    }

}
