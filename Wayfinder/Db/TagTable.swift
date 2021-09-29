// Wayfinder

import Foundation

/// The tag table
struct Tag : Identifiable, SqlTable {
    static var createStatement: String {
        return """
        CREATE TABLE tag(
            id INTEGER PRIMARY KEY,
            reflectionId INT REFERENCES reflection(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE,
            name TEXT
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
        let sql = "SELECT DISTINCT name FROM tag"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var tags: [String] = []
        
        while (true) {
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                break
            }
            
            let tagName = String(cString: sqlite3_column_text(stmt, 0))

            tags.append(tagName)
        }
        
        return tags
    }
    
    func fetchTags(for reflectionId: Int64) throws -> [String] {
        let sql = "SELECT name FROM tag WHERE reflectionId = ?"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_int64(stmt, 1, reflectionId) == SQLITE_OK else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        var tags: [String] = []
        
        while (true) {
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                break
            }
            
            let tagName = String(cString: sqlite3_column_text(stmt, 0))

            tags.append(tagName)
        }
        
        return tags
    }
    
    func insertTags(for reflectionId: Int64, tags: [String]) throws {
        
    }
}
