// Wayfinder

import Foundation

/// The tag table
struct Tag : Identifiable {
    static var createStatement: String {
        return """
        CREATE TABLE tag(
            id INTEGER PRIMARY KEY,
            name TEXT,
            reflection INT REFERENCES reflection
                ON UPDATE CASCADE
                ON DELETE CASCADE
        );
        CREATE INDEX tagindex ON tag(reflection);
        """
    }
    static var dropStatement: String {
        // NOTE: index is automatically dropped with the table
        // "All indices and triggers associated with the table are also deleted"
        // https://sqlite.org/lang_droptable.html
        return """
        DROP TABLE tag;
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
        let sql = "SELECT name FROM tag WHERE reflection = ?"
        
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
        if tags.isEmpty {
            return
        }
        
        // Values are inserted in tuples
        // (1, 'dev'), (1, 'meeting'), (2, 'dev'), etc.
        let questionMarkTuples = [String](repeating: "(?, ?)", count: tags.count)
        let sql = """
            INSERT INTO tag (reflection, name)
            VALUES \(questionMarkTuples.joined(separator: ","))
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        for (i, tagName) in tags.enumerated() {
            let questionMarkIndex = Int32(i) * 2
            guard sqlite3_bind_int64(stmt, questionMarkIndex + 1, reflectionId) == SQLITE_OK
                    && sqlite3_bind_text(stmt, questionMarkIndex + 2, tagName, -1, SQLITE_TRANSIENT) == SQLITE_OK
            else {
                throw SqliteError.Bind(message: errorMessage)
            }
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    func deleteTags(for reflectionId: Int64, tags: [String]) throws {
        if tags.isEmpty {
            return
        }
        
        let questionMarks = [String](repeating: "?", count: tags.count)
        let sql = """
            DELETE FROM tag
            WHERE reflection = ? AND name IN (\(questionMarks.joined(separator: ",")));
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_int64(stmt, 1, reflectionId) == SQLITE_OK else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        for (i, tagName) in tags.enumerated() {
            let questionMarkIndex = Int32(i) + 1
            guard sqlite3_bind_text(stmt, questionMarkIndex + 1, tagName, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                throw SqliteError.Bind(message: errorMessage)
            }
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    /// Delete all tags for a reflection
    func deleteTags(for reflectionId: Int64) throws {
        let sql = """
            DELETE FROM tag
            WHERE reflection = ?;
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_int64(stmt, 1, reflectionId) == SQLITE_OK else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    /// Sync tags for a given reflection
    func syncTags(for reflectionId: Int64, tags: [String]) throws {
        // This just deletes all tags for the reflection and adds back in the requested ones.
        // Could be smarter by only deleting the ones you need and only adding the ones you need
        try deleteTags(for: reflectionId)
        try insertTags(for: reflectionId, tags: tags)
    }
    
    /// Rename all tags with one name to another name
    func renameTags(from oldName: String, to newName: String) throws {
        let sql = "UPDATE tag SET name = ? WHERE name = ?"
        
        let stmt = try? prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_text(stmt, 1, newName, -1, SQLITE_TRANSIENT) == SQLITE_OK
                && sqlite3_bind_text(stmt, 2, oldName, -1, SQLITE_TRANSIENT) == SQLITE_OK
        else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
}
