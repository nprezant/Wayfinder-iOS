// WayfinderTests

import XCTest
@testable import Wayfinder

class AxisTableTests: XCTestCase {
    
    var dbBeforeAxis: SqliteDatabase? = nil

    override func setUpWithError() throws {
        var testData = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note", axis: "Work").reflection,
        ]
        
        dbBeforeAxis = try TestUtils.makeDatabase(with: &testData)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
