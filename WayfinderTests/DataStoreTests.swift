// WayfinderTests

import XCTest
@testable import Wayfinder
import SwiftUI

class DataStoreTests: XCTestCase {
    
    var testData: [Reflection] = []

    override func setUpWithError() throws {
        testData = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work").reflection,
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
        
        let expectation = XCTestExpectation(description: "Add two reflections individually")
        
        // Add first reflection
        dataStore.add(reflection: testData[0]) { [self] result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                
            case .success(let dbAssignedId):
                XCTAssertEqual(1, dbAssignedId) // Should be first entry in database
            }
            
            self.testData[0].id = 1
            
            // Add second reflection
            dataStore.add(reflection: testData[1]) { [self] result in
                switch result {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                    
                case .success(let dbAssignedId):
                    XCTAssertEqual(2, dbAssignedId) // Should be second entry in database
                }
                
                self.testData[1].id = 2
                
                // Read reflection list and ensure they are equal
                dataStore.sync() {
                    XCTAssertEqual(Array(testData[0...1]), dataStore.reflections)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testAddedReflectionIds() throws {
        XCTAssertEqual(testData[0].id, 0)
        XCTAssertEqual(testData[1].id, 0)
        XCTAssertEqual(testData[2].id, 0)
        XCTAssertEqual(testData[3].id, 0)
        
        let dataStore = DataStore(inMemory: true)
        dataStore.add(reflections: &testData)
        
        let expectation = XCTestExpectation(description: "Add many reflections")
        
        dataStore.sync() {
            XCTAssertEqual(dataStore.reflections.count, 4)
            XCTAssertEqual(dataStore.reflections[0].id, 1)
            XCTAssertEqual(dataStore.reflections[1].id, 2)
            XCTAssertEqual(dataStore.reflections[2].id, 3)
            XCTAssertEqual(dataStore.reflections[3].id, 4)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testAddReflections() throws {
        let dataStore = DataStore(inMemory: true)
        dataStore.add(reflections: &testData)
        
        let expectation = XCTestExpectation(description: "Add many reflections")
        
        dataStore.sync() { [testData] in
            XCTAssertEqual(testData, dataStore.reflections)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testDeleteReflection() throws {
        let dataStore = try! populatedDataStore()
        
        let expectation = XCTestExpectation(description: "Delete one reflection")
        
        // Delete second reflection
        dataStore.delete(reflectionIds: [2]) {error in
            
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            
            dataStore.sync() { [self] in
                testData.remove(at: 1) // Remove second reflection from test data list
                XCTAssertEqual(testData, dataStore.reflections)
                expectation.fulfill()
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testDeleteReflections() throws {
        let dataStore = try! populatedDataStore()
        
        let expectation = XCTestExpectation(description: "Delete many reflections")
        
        // Delete first and second reflection
        dataStore.delete(reflectionIds: [1, 2]) {error in
            
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            
            dataStore.sync() { [self] in
                testData.removeAll(where: {[1, 2].contains($0.id)}) // Remove first and second reflection from test data list
                XCTAssertEqual(testData, dataStore.reflections)
                expectation.fulfill()
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testUpdateReflection() throws {
        let dataStore = try! populatedDataStore()
        
        let expectation = XCTestExpectation(description: "Update a reflection")
        
        let newSecondReflection = Reflection.Data(id: 2, name: "Frank", isFlowState: true, engagement: 0, energy: 100, date: Date(), note: "").reflection
        
        // Delete first and second reflection
        dataStore.update(reflection: newSecondReflection) {error in
            
            if let error = error {
                XCTFail(error.localizedDescription)
            }
            
            dataStore.sync() { [self] in
                XCTAssertEqual(dataStore.reflections[1], newSecondReflection)
                
                testData[1] = newSecondReflection
                XCTAssertEqual(testData, dataStore.reflections)
                
                expectation.fulfill()
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
    }

    func testPerformanceExample() throws {
        // Add a bunch of data
        for _ in 1...5 {
            testData += testData
        }
        self.measure {
            let _ = try! populatedDataStore()
        }
    }

}
