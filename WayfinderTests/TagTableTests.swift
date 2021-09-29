// WayfinderTests

import XCTest
@testable import Wayfinder

class TagTableTests: XCTestCase {
    
    var testDataNoTags: [Reflection] = []

    override func setUpWithError() throws {
        testDataNoTags = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note").reflection,
        ]
    }

    override func tearDownWithError() throws {
        testDataNoTags.removeAll()
    }
    
    func testFetchAllUniqueTags() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = db.fetchAllUniqueTags()
        let expectedTags: [String] = [] // TODO add tags
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchAllUniqueTagsWhenNonePresent() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = db.fetchAllUniqueTags()
        let expectedTags: [String] = []
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchTagsForReflection() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = try db.fetchTags(for: 1)
        let expectedTags: [String] = []
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testFetchTagsForReflectionNoMatch() throws {
        let db = try! TestUtils.makeDatabase(with: &testDataNoTags)
        let dbTags = try db.fetchTags(for: 1000)
        let expectedTags: [String] = []
        XCTAssertEqual(dbTags, expectedTags)
    }
    
    func testDeleteReflectionCascadesToTags() throws {
        
    }
    
    func testUpdateReflectionCascadesToTags() throws {
        
    }

}
