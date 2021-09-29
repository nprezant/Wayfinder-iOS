// Wayfinder

import Foundation

/// The table itself
struct Reflection : Identifiable, Equatable {
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
    
    var tags: [String] // References tag table
    
    // NOTE: no need to implement static func ==(lhs, rhs). By default all properties are compared
}

/// Example data, useful for previews
extension Reflection {
    static var exampleData: [Reflection] {
        [
            Reflection(id: 1, name: "iOS dev", isFlowState: true.intValue, engagement: 70, energy: -20, date: Int64(Date().timeIntervalSince1970), note: "Exhausting", tags: ["dev", "solo"]),
            Reflection(id: 2, name: "Sleeping", isFlowState: false.intValue, engagement: 50, energy: 60, date: Int64(Date().timeIntervalSince1970), note: "Not long enough", tags: []),
        ]
    }
}

/// A friendlier version of the table data (e.g. bool instead of int, Date instead of int time since 1970, etc.)
extension Reflection {
    struct Data {
        var id: Int64 = 0
        var name: String = ""
        var isFlowState: Bool = false
        var engagement: Int64 = 0
        var energy: Int64 = 0
        var date: Date = Date()
        var note: String = ""
        var tags: [String] = []
        
        var reflection: Reflection {
            return Reflection(id: id, name: name, isFlowState: isFlowState.intValue, engagement: engagement, energy: energy, date: Int64(date.timeIntervalSince1970), note: note, tags: tags)
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

/// A way to combine and average multiple reflections into a single summary
extension Reflection {
    struct Averaged {
        var ids: [Int64]
        var flowStateYes: Int
        var flowStateNo: Int
        var engagement: Int
        var energy: Int
        
        static func exampleData() -> Averaged {
            return Averaged(ids: [1], flowStateYes: 1, flowStateNo: 2, engagement: 25, energy: -10)
        }
        
        static func make(from reflections: [Reflection]) -> Averaged? {
            if reflections.isEmpty {
                return nil
            }
            let ids = reflections.map{$0.id}
            let flowStateYes = reflections.filter{$0.isFlowState.boolValue}.count
            let flowStateNo = reflections.count - flowStateYes
            let averageEngagement = reflections.map{Int($0.engagement)}.reduce(0, +) / reflections.count
            let averageEnergy = reflections.map{Int($0.energy)}.reduce(0, +) / reflections.count
            return Averaged(ids: ids, flowStateYes: flowStateYes, flowStateNo: flowStateNo, engagement: averageEngagement, energy: averageEnergy)
        }
    }
}

/// Database operations that involve the reflection table
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
        
        let newReflectionId = lastInsertedRowId()
        
        try insertTags(for: newReflectionId, tags: reflection.tags) // TODO should the whole block be wrapped in a transaction?
        
        return newReflectionId
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
        
        try insertTags(for: reflection.id, tags: reflection.tags) // TODO should the whole block be wrapped in a transaction?
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
    
    func reflections() -> [Reflection] {
        let querySql = "SELECT id, name, isFlowState, engagement, energy, date, note FROM reflection"
        
        let stmt = try? prepare(sql: querySql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var reflections: [Reflection] = []
        
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
            
            let tags = (try? fetchTags(for: id)) ?? []
            
            let reflection = Reflection(id: id, name: name, isFlowState: isFlowState, engagement: engagement, energy: energy, date: date, note: note, tags: tags)

            reflections.append(reflection)
        }
        
        return reflections
    }
    
}
