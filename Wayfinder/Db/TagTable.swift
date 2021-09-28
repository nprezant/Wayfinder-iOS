// Wayfinder

import Foundation

/// The tag table
struct Tag : Identifiable, SqlTable {
    static var createStatement: String {
        return """
        CREATE TABLE tag(
            id INTEGER PRIMARY KEY,
            name TEXT,
            reflection INT REFERENCES reflection(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE
        );
        """
    }
    
    var id: Int64
    var name: String
    var reflection: Int64
}

/// Tag related database methods
extension SqliteDatabase {
    
    func fetchAllUniqueTags() -> [String] {
        return []
    }
    
    func fetchTags(for reflectionId: Int64) throws -> [String] {
        return []
    }
    
    func insertTags(for reflectionId: Int64, tags: [String]) throws {
        
    }
}
