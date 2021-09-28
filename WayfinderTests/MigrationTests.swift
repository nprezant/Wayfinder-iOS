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
    
    static func makeTempPath() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    }

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }
    
    func testCreateNewDatabaseMigratesAllTheWay() throws {
        let db = try! SqliteDatabase.open(at: MigrationTests.makeTempPath())
        XCTAssertEqual(db.version, SqliteDatabase.latestVersion)
    }
    
    func testOriginal() throws {
        let db = try! SqliteDatabase.open(at: MigrationTests.makeTempPath())
        let schemaShouldBe: [String] = ["""
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
        
        XCTAssertEqual(db.tableSchemas.withCondensedWhitespace(), schemaShouldBe)
    }

    func testMigrate0To1() throws {
        
    }

}
