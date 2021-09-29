// WayfinderTests

import Foundation
@testable import Wayfinder

class TestUtils
{
    /// Creates a temporary path
    /// Suitable for test database locations
    static func makeTempPath() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    }
    
    /// Creates a database and adds the reflections
    /// Updates inserted reflection data with database ids
    static func makeDatabase(with reflections: inout [Reflection]) throws -> SqliteDatabase {
        let db = try! SqliteDatabase.openInMemory()
        for idx in reflections.indices {
            let insertedId = try! db.insert(reflection: reflections[idx])
            reflections[idx].id = insertedId
        }
        return db
    }
}
