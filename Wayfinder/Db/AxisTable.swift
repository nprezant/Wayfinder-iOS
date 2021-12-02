// Wayfinder

import Foundation

/// The axis table
struct Axis : Identifiable, Equatable {    
    var id: Int64
    var name: String
    var hidden: Int64
}

/// A friendlier version of the table data
extension Axis {
    struct Data {
        var id: Int64 = 0
        var name: String = ""
        var hidden: Bool = false
        
        var axis: Axis {
            return Axis(id: id, name: name, hidden: hidden.intValue)
        }
    }

    var data: Data {
        return Data(id: id, name: name, hidden: hidden.boolValue)
    }

    mutating func update(from data: Data) {
        id = data.id
        name = data.name
        hidden = data.hidden.intValue
    }
}

/// Tag related database methods
extension SqliteDatabase {
    
    func fetchDistinctVisibleAxisNames() -> [String] {
        let sql = "SELECT DISTINCT name FROM axis WHERE hidden = 0"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var axes: [String] = []
        
        while (true) {
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                break
            }
            
            let axisName = String(cString: sqlite3_column_text(stmt, 0))

            axes.append(axisName)
        }
        
        return axes
    }
    
    func fetchAllAxes() -> [Axis] {
        let sql = "SELECT id, name, hidden FROM axis"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        var axes: [Axis] = []
        
        while (true) {
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                break
            }
            
            let id = sqlite3_column_int64(stmt, 0)
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let isHidden = sqlite3_column_int64(stmt, 2)

            axes.append(Axis(id: id, name: name, hidden: isHidden))
        }
        
        return axes
    }
    
    func fetchAxis(name targetName: String) -> Axis? {
        let sql = "SELECT id, name, hidden FROM axis WHERE name = ?1 LIMIT 1"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_text(stmt, 1, targetName, -1, SQLITE_TRANSIENT) == SQLITE_OK
        else {
            return nil
        }
        
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        
        let id = sqlite3_column_int64(stmt, 0)
        let name = String(cString: sqlite3_column_text(stmt, 1))
        let isHidden = sqlite3_column_int64(stmt, 2)
        
        return Axis(id: id, name: name, hidden: isHidden)
    }
    
    func insert(axis name: String) throws {
        let sql = "INSERT INTO axis (name, hidden) VALUES (?1, FALSE);"
        
        let stmt = try! prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard
            sqlite3_bind_text(stmt, 1, name, -1, SQLITE_TRANSIENT) == SQLITE_OK
        else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    func delete(axis: String) throws {
        let sql = """
            DELETE FROM axis
            WHERE name = ?1;
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_bind_text(stmt, 1, axis, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw SqliteError.Bind(message: errorMessage)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    func delete(axes: [String]) throws {
        if axes.isEmpty {
            return
        }
        
        let questionMarks = [String](repeating: "?", count: axes.count)
        let sql = """
            DELETE FROM axis
            WHERE name IN (\(questionMarks.joined(separator: ",")));
        """
        
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        for (i, tagName) in axes.enumerated() {
            let questionMarkIndex = Int32(i) + 1
            guard sqlite3_bind_text(stmt, questionMarkIndex, tagName, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
                throw SqliteError.Bind(message: errorMessage)
            }
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
}
