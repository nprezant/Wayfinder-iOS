// WayfinderTests

import XCTest
@testable import Wayfinder
import SwiftUI

class DataStoreTests: XCTestCase {
    
    var testData: [Reflection] = []

    override func setUpWithError() throws {
        testData = [
            Reflection.Data(id: 0, name: "First Reflection", isFlowState: false, engagement: 20, energy: 100, date: Date(), note: "", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Second Reflection", isFlowState: true, engagement: 0, energy: -10, date: Date(), note: "Second note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Third Reflection", isFlowState: false, engagement: 10, energy: -50, date: Date(), note: "Third note", axis: "Work").reflection,
            Reflection.Data(id: 0, name: "Fourth Reflection", isFlowState: true, engagement: 50, energy: 30, date: Date(), note: "Fourth note", axis: "Work").reflection,
        ]
    }

    override func tearDownWithError() throws {
        testData.removeAll()
    }
    
    func populatedDataStore() throws -> Store {
        let store = Store(inMemory: true)
        store.add(reflections: &testData)
        return store
    }

    func testAddReflection() throws {
        let store = Store(inMemory: true)
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Add two reflections individually")
        
        // Add first reflection
        store.add(reflection: testData[0]) { [self] result in
            switch result {
            case .failure(let error):
                XCTFail("\(error)")
                
            case .success(let dbAssignedId):
                XCTAssertEqual(1, dbAssignedId) // Should be first entry in database
            }
            
            self.testData[0].id = 1
            
            // Add second reflection
            store.add(reflection: testData[1]) { [self] result in
                switch result {
                case .failure(let error):
                    XCTFail("\(error)")
                    
                case .success(let dbAssignedId):
                    XCTAssertEqual(2, dbAssignedId) // Should be second entry in database
                }
                
                self.testData[1].id = 2
                
                // Read reflection list and ensure they are equal
                store.sync() {
                    XCTAssertEqual(Array(testData[0...1]), store.reflections)
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
        
        let store = Store(inMemory: true)
        store.add(reflections: &testData)
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Add many reflections")
        
        store.sync() {
            XCTAssertEqual(store.reflections.count, 4)
            XCTAssertEqual(store.reflections[0].id, 1)
            XCTAssertEqual(store.reflections[1].id, 2)
            XCTAssertEqual(store.reflections[2].id, 3)
            XCTAssertEqual(store.reflections[3].id, 4)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testAddReflections() throws {
        let store = Store(inMemory: true)
        store.add(reflections: &testData)
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Add many reflections")
        
        store.sync() { [testData] in
            XCTAssertEqual(testData, store.reflections)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testDeleteReflection() throws {
        let store = try populatedDataStore()
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Delete one reflection")
        
        // Delete second reflection
        store.delete(reflectionIds: [2]) {error in
            
            if let error = error {
                XCTFail("\(error)")
            }
            
            store.sync() { [self] in
                testData.remove(at: 1) // Remove second reflection from test data list
                XCTAssertEqual(testData, store.reflections)
                expectation.fulfill()
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testDeleteReflections() throws {
        let store = try populatedDataStore()
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Delete many reflections")
        
        // Delete first and second reflection
        store.delete(reflectionIds: [1, 2]) {error in
            
            if let error = error {
                XCTFail("\(error)")
            }
            
            store.sync() { [self] in
                testData.removeAll(where: {[1, 2].contains($0.id)}) // Remove first and second reflection from test data list
                XCTAssertEqual(testData, store.reflections)
                expectation.fulfill()
            }
            
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testUpdateReflection() throws {
        let store = try populatedDataStore()
        store.activeAxis = testData[0].axis
        
        let expectation = XCTestExpectation(description: "Update a reflection")
        
        let newSecondReflection = Reflection.Data(id: 2, name: "Frank", isFlowState: true, engagement: 0, energy: 100, date: Date(), note: "", axis: "Work").reflection
        
        // Delete first and second reflection
        store.update(reflection: newSecondReflection) {error in
            
            if let error = error {
                XCTFail("\(error)")
            }
            
            store.sync() { [self] in
                XCTAssertEqual(store.reflections[1], newSecondReflection)
                
                testData[1] = newSecondReflection
                XCTAssertEqual(testData, store.reflections)
                
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
