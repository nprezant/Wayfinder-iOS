// Wayfinder

protocol SqlTable {
    static var createStatement: String { get }
}

struct Reflection : SqlTable {
    static var createStatement: String {
        return """
        CREATE TABLE Reflection(
            id INT PRIMARY KEY NOT NULL,
            name TEXT,
            isFlowState BOOL,
            engagement INT,
            energy INT,
            date INT
        );
        """
    }
    
    let id: Int64
    let name: String
    let isFlowState: Bool
    let engagement: Int64
    let energy: Int64
    let date: Int64 // unix epoch time
}

extension Reflection {
    static var exampleData: [Reflection] {
        [
            Reflection(id: 1, name: "iOS dev", isFlowState: false, engagement: 70, energy: -20, date: 1000000),
            Reflection(id: 2, name: "Sleeping", isFlowState: false, engagement: 50, energy: 60, date: 1000000),
        ]
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
    func insertReflection(reflection: Reflection) throws {
        let insertSql = """
            INSERT INTO Reflection
                (id, name, isFlowState, engagement, energy, date)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        let stmt = try prepare(sql: insertSql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_int64(stmt, 1, reflection.id) == SQLITE_OK
                && sqlite3_bind_text(stmt, 2, reflection.name, -1, nil) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 3, reflection.isFlowState.intValue) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 4, reflection.engagement) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 5, reflection.energy) == SQLITE_OK
                && sqlite3_bind_int64(stmt, 6, reflection.date) == SQLITE_OK
        else {
            throw SqliteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    func reflection(stmt: OpaquePointer?) -> Reflection? {
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        
        // TODO verify rows exist? Or is that guarded by the SQLITE_ROW check?
        
        let id = sqlite3_column_int64(stmt, 0)
        let name = String(cString: sqlite3_column_text(stmt, 1))
        let isFlowState = sqlite3_column_int64(stmt, 2).boolValue
        let engagement = sqlite3_column_int64(stmt, 3)
        let energy = sqlite3_column_int64(stmt, 4)
        let date = sqlite3_column_int64(stmt, 5)
        
        return Reflection(id: id, name: name, isFlowState: isFlowState, engagement: engagement, energy: energy, date: date)
    }
    
    func reflection(id: Int64) -> Reflection? {
        let querySql = "SELECT id, name, isFlowState, engagement, energy, date FROM Reflection WHERE id = ?;"
        
        let stmt = try? prepare(sql: querySql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_int64(stmt, 1, id) == SQLITE_OK else {
            return nil
        }
        
        return reflection(stmt: stmt)
    }
    
    func reflections() -> [Reflection] {
        let querySql = "SELECT id, name, isFlowState, engagement, energy, date FROM Reflection"
        
        let stmt = try? prepare(sql: querySql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var reflections: [Reflection] = []
        
        while (true) {
            let reflection = reflection(stmt: stmt)
            if reflection != nil {
                reflections.append(reflection!)
            } else {
                break
            }
        }
        
        return reflections
    }
    
}
