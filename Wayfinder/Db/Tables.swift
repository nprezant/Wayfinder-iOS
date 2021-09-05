// Wayfinder

import Foundation

// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Statement.swift#L179
// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Database.swift#L14
let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

protocol SqlTable {
    static var createStatement: String { get }
}

struct Reflection : Identifiable, SqlTable {
    static var createStatement: String {
        return """
        CREATE TABLE reflection(
            id INTEGER PRIMARY KEY,
            name TEXT,
            isFlowState BOOL,
            engagement INT,
            energy INT,
            date INT,
            note TEXT
        );
        """
    }
    
    var id: Int64
    var name: String
    var isFlowState: Int64
    var engagement: Int64
    var energy: Int64
    var date: Int64 // Unix epoch time
    var note: String
}

extension Reflection {
    static var exampleData: [Reflection] {
        [
            Reflection(id: 1, name: "iOS dev", isFlowState: true.intValue, engagement: 70, energy: -20, date: Int64(Date().timeIntervalSince1970), note: "Exhausting"),
            Reflection(id: 2, name: "Sleeping", isFlowState: false.intValue, engagement: 50, energy: 60, date: Int64(Date().timeIntervalSince1970), note: "Not long enough"),
        ]
    }
}

extension Reflection {
    struct Data {
        var id: Int64 = 0
        var name: String = ""
        var isFlowState: Bool = false
        var engagement: Int64 = 50
        var energy: Int64 = 0
        var date: Date = Date()
        var note: String = ""
        
        var reflection: Reflection {
            return Reflection(id: id, name: name, isFlowState: isFlowState.intValue, engagement: engagement, energy: energy, date: Int64(date.timeIntervalSince1970), note: note)
        }
    }

    var data: Data {
        return Data(id: id, name: name, isFlowState: isFlowState.boolValue, engagement: engagement, energy: energy, date: Date(timeIntervalSince1970: TimeInterval(date)), note: note)
    }

    mutating func update(from data: Data) {
        id = data.id
        name = data.name
        isFlowState = data.isFlowState.intValue
        engagement = data.engagement
        energy = data.energy
        date = Int64(data.date.timeIntervalSince1970)
        note = data.note
    }
}

extension Bool {
    var intValue: Int64 { self ? 1 : 0 }
}

extension Int64 {
    var boolValue: Bool {
        return self != 0
    }
}

extension SqliteDatabase {
    
    func insert(reflection: Reflection) throws -> Int64 {
        let sql = """
            INSERT INTO reflection
                (name, isFlowState, engagement, energy, date, note)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_text(stmt, 1, reflection.name, -1, SQLITE_TRANSIENT) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 2, reflection.isFlowState) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 3, reflection.engagement) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 4, reflection.energy) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 5, reflection.date) == SQLITE_OK
                && sqlite3_bind_text(stmt, 6, reflection.note, -1, SQLITE_TRANSIENT) == SQLITE_OK
        else {
            throw SqliteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
        
        return lastInsertedRowId()
    }
    
    // Update an existing reflection with a matching ID
    func update(reflection: Reflection) throws {
        let sql = """
            UPDATE reflection
            SET (name, isFlowState, engagement, energy, date, note)
            = (?, ?, ?, ?, ?, ?)
            WHERE id = ?;
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_text(stmt, 1, reflection.name, -1, SQLITE_TRANSIENT) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 2, reflection.isFlowState) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 3, reflection.engagement) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 4, reflection.energy) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 5, reflection.date) == SQLITE_OK
                && sqlite3_bind_text(stmt, 6, reflection.note, -1, SQLITE_TRANSIENT) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 7, reflection.id) == SQLITE_OK
        else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    // Delete reflections with matching IDs
    func delete(reflectionsIds: [Int64]) throws {
        if reflectionsIds.isEmpty {
            return
        }
        
        let questionMarks = [String](repeating: "?", count: reflectionsIds.count)
        let sql = """
            DELETE FROM reflection
            WHERE id IN (\(questionMarks.joined(separator: ",")));
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        for (i, id) in reflectionsIds.enumerated() {
            guard sqlite3_bind_int64(stmt, Int32(i) + 1, id) == SQLITE_OK else {
                throw SqliteError.Bind(message: errorMessage)
            }
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    func reflectionStep(stmt: OpaquePointer?) -> Reflection? {
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        
        // TODO verify rows exist? Or is that guarded by the SQLITE_ROW check?
        
        let id = sqlite3_column_int64(stmt, 0)
        let name = String(cString: sqlite3_column_text(stmt, 1))
        let isFlowState = sqlite3_column_int64(stmt, 2)
        let engagement = sqlite3_column_int64(stmt, 3)
        let energy = sqlite3_column_int64(stmt, 4)
        let date = sqlite3_column_int64(stmt, 5)
        let note = String(cString: sqlite3_column_text(stmt, 6))
        
        return Reflection(id: id, name: name, isFlowState: isFlowState, engagement: engagement, energy: energy, date: date, note: note)
    }
    
    func reflection(id: Int64) -> Reflection? {
        let querySql = "SELECT id, name, isFlowState, engagement, energy, date, note FROM reflection WHERE id = ?;"
        
        let stmt = try? prepare(sql: querySql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_int64(stmt, 1, id) == SQLITE_OK else {
            return nil
        }
        
        return reflectionStep(stmt: stmt)
    }
    
    func reflections() -> [Reflection] {
        let querySql = "SELECT id, name, isFlowState, engagement, energy, date, note FROM reflection"
        
        let stmt = try? prepare(sql: querySql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var reflections: [Reflection] = []
        
        while (true) {
            let reflection = reflectionStep(stmt: stmt)
            if reflection != nil {
                reflections.append(reflection!)
            } else {
                break
            }
        }
        
        return reflections
    }
    
}
