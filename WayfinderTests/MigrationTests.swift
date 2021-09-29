// WayfinderTests

import XCTest
@testable import Wayfinder

extension String {
    func withCondensedWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension Array where Element == String {
    func withCondensedWhitespace() -> [String] {
        var condensed: [String] = []
        for str in self {
            condensed.append(str.withCondensedWhitespace())
        }
        return condensed
    }
}

class MigrationTests: XCTestCase {
    
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
    
    func testNewDatabaseMigrates() throws {
        let db = try! SqliteDatabase.openInMemory()
        XCTAssertEqual(db.version, SqliteDatabase.latestVersion)
    }
    
    static var schema0: [String] = [
        """
        CREATE TABLE reflection(
            id INTEGER PRIMARY KEY,
            name TEXT,
            isFlowState BOOL,
            engagement INT,
            energy INT,
            date INT,
            note TEXT
        )
        """].withCondensedWhitespace()
    
    static var schema1: [String] = [
        """
        CREATE TABLE reflection(
            id INTEGER PRIMARY KEY,
            name TEXT,
            isFlowState BOOL,
            engagement INT,
            energy INT,
            date INT,
            note TEXT
        )
        """,
        """
        CREATE TABLE tag(
            id INTEGER PRIMARY KEY,
            reflectionId INT REFERENCES reflection(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            name TEXT
        )
        """].withCondensedWhitespace()
    
    func testVersion0() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 0)
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema0)
    }
    
    func testVersion0Backwards() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 1)
        try db.migrate(to: 0)
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema0)
    }
    
    func testVersion1() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 1)
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema1)
    }
    
    func testLatest() throws {
        let db = try! SqliteDatabase.openInMemory()
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema1)
    }

    func testMigrate0To1() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 0)
        for i in testData.indices {
            testData[i].id = try db.insert(reflection: testData[i])
        }
        
        try db.migrate(to: 1)
        
        let loadedReflections = db.reflections()
        XCTAssertEqual(loadedReflections, testData)
    }

    func testCanMigrateBackwards() throws {
        let db = try SqliteDatabase.openInMemory()
        try db.migrate(to: 0)
    }
}
