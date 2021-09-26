// WayfinderTests

import XCTest
@testable import Wayfinder
import SwiftUI

class DataStoreTests: XCTestCase {
    
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
    
    func populatedDataStore() throws -> DataStore {
        let dataStore = DataStore(inMemory: true)
        dataStore.add(reflections: &testData)
        return dataStore
    }

    func testAddReflection() throws {
        let dataStore = DataStore(inMemory: true)
        
        // Add first reflection
        dataStore.add(reflection: testData[0]) { [testData] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                
            case .success(let dbAssignedId):
                XCTAssertEqual(1, dbAssignedId) // Should be first entry in database
            }
            
            // Add second reflection
            dataStore.add(reflection: testData[1]) { [testData] result in
                switch result {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                    
                case .success(let dbAssignedId):
                    XCTAssertEqual(2, dbAssignedId) // Should be second entry in database
                }
                
                // Read reflection list and ensure they are equal
                dataStore.loadReflections() { reflections in
                    XCTAssertEqual(Array(testData[0...1]), reflections)
                }
            }
        }
    }
    
    func testAddReflections() throws {
        let dataStore = DataStore(inMemory: true)
        dataStore.add(reflections: &testData)
        
        let expectation = XCTestExpectation(description: "Add many reflections")
        
        dataStore.loadReflections() { [testData] reflections in
            XCTAssertEqual(testData, reflections)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2000)
    }
    
    func testDeleteReflection() throws {
        // TODO implement
    }
    
    func testDeleteReflections() throws {
        // TODO implement
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            let _ = try! populatedDataStore()
        }
    }

}
