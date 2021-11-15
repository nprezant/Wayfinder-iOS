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
            name TEXT,
            reflection INT REFERENCES reflection
                ON UPDATE CASCADE
                ON DELETE CASCADE
        )
        """,
        """
        CREATE INDEX tagindex ON tag(reflection)
        """].withCondensedWhitespace()
    
    static var schema2: [String] = [
        """
        CREATE TABLE reflection(
            id INTEGER PRIMARY KEY,
            name TEXT,
            isFlowState BOOL,
            engagement INT,
            energy INT,
            date INT,
            note TEXT ,
            axis INT REFERENCES axis
                ON UPDATE CASCADE)
        """,
        """
        CREATE TABLE tag(
            id INTEGER PRIMARY KEY,
            name TEXT,
            reflection INT REFERENCES reflection
                ON UPDATE CASCADE
                ON DELETE CASCADE
        )
        """,
        """
        CREATE INDEX tagindex ON tag(reflection)
        """,
        """
        CREATE TABLE axis(
            id INTEGER PRIMARY KEY,
            name TEXT UNIQUE,
            hidden BOOL
        )
        """,
        """
        CREATE INDEX indexAxisHidden ON axis(hidden)
        """,
        """
        CREATE INDEX indexReflectionAxis ON reflection(axis)
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
    
    func testVersion1Backwards() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 2)
        try db.migrate(to: 1)
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema1)
    }
    
    func testVersion2() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 2)
        for index in 0...db.tableSchemas.count-1 {
            XCTAssertEqual(db.tableSchemas[index].withCondensedWhitespace(), MigrationTests.schema2[index])
        }
    }
    
    func testLatest() throws {
        let db = try! SqliteDatabase.openInMemory()
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), MigrationTests.schema2)
    }

    func testMigrate0To1() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 0)
        try db.executeMany(sql: """
        INSERT INTO reflection (name, isFlowState, engagement, energy, date, note) VALUES ('reflection1', 1, 25, 80, 10000, 'no notes');
        INSERT INTO reflection (name, isFlowState, engagement, energy, date, note) VALUES ('reflection2', 0, 10, 20, 50000, 'bummer');
        """)
        
        try db.migrate(to: 1)
        
        let sql = "SELECT id, name, isFlowState, engagement, energy, date, note, FROM reflection ORDER BY date DESC"
        
        let stmt = try? db.prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        let count: Int = 0
        while (true) {
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                break
            }
            
            let id = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let isFlowState = sqlite3_column_int64(stmt, 2)
            let engagement = sqlite3_column_int64(stmt, 3)
            let energy = sqlite3_column_int64(stmt, 4)
            let date = sqlite3_column_int64(stmt, 5)
            let note = String(cString: sqlite3_column_text(stmt, 6))
            
            if count == 0 {
                XCTAssertEqual(id, 1)
                XCTAssertEqual(name, "reflection1")
                XCTAssertEqual(isFlowState, false.intValue)
                XCTAssertEqual(engagement, 25)
                XCTAssertEqual(energy, 80)
                XCTAssertEqual(date, 10000)
                XCTAssertEqual(note, "no notes")
            } else if count == 1 {
                XCTAssertEqual(id, 2)
                XCTAssertEqual(name, "reflection2")
                XCTAssertEqual(isFlowState, true.intValue)
                XCTAssertEqual(engagement, 10)
                XCTAssertEqual(energy, 20)
                XCTAssertEqual(date, 50000)
                XCTAssertEqual(note, "bummer")
            }
        }
    }
    
    /// When migrating from schema 1 to schema 2, we are adding the view table
    /// In schema 1 there are no views. In schema 2 every reflection must have a view
    /// During the migration a single view should be made ("Work", hidden = false)
    /// and all reflections should be assigned to it.
    func testMigrate1To2() throws {
        let db = try! SqliteDatabase.openInMemory(targetVersion: 1)
        try db.executeMany(sql: """
        INSERT INTO reflection (name, isFlowState, engagement, energy, date, note) VALUES ('reflection1', 1, 25, 80, 10000, 'no notes');
        INSERT INTO reflection (name, isFlowState, engagement, energy, date, note) VALUES ('reflection2', 0, 10, 20, 50000, 'bummer');
        """)
        
        try db.migrate(to: 2)
        
        // A single axis should be made during the migration
        let defaultAxis = Axis(id: 1, name: "Work", hidden: false.intValue)
        
        // A single axis should be made that is visible
        let axisNames = db.fetchDistinctVisibleAxisNames()
        XCTAssertEqual(axisNames.count, 1)
        XCTAssertEqual(axisNames.first, "Work")
        
        // A single axis should be made overall
        let axes = db.fetchAllAxes()
        XCTAssertEqual(axes.count, 1)
        XCTAssertEqual(axes.first, defaultAxis)
        
        // The reflections migrated should be attached to the newly created axis
        let reflections = try db.fetchReflections()
        XCTAssertEqual(reflections.count, 2)
        XCTAssertEqual(reflections.first?.axis, defaultAxis.name)
    }

    func testCanMigrateBackwards() throws {
        let db = try SqliteDatabase.openInMemory()
        try db.migrate(to: 0)
    }
}
