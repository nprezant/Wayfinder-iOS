// Wayfinder

import Foundation

enum SqliteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}

class SqliteDatabase {
    
    private let dbPointer: OpaquePointer? // C pointer
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    // Open database connection
    static func open(atPath: URL) throws -> SqliteDatabase {
        if FileManager().fileExists(atPath: atPath.path) {
            return try openExisting(atPath: atPath.absoluteString)
        } else {
            return try createNew(atPath: atPath.absoluteString)
        }
    }
    
    private static func openExisting(atPath: String) throws -> SqliteDatabase {
        var db: OpaquePointer?
        
        if sqlite3_open(atPath, &db) == SQLITE_OK {
            
            return SqliteDatabase(dbPointer: db)
            
        } else {
            
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SqliteError.OpenDatabase(message: message)
                
            } else {
                throw SqliteError
                .OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    private static func createNew(atPath: String) throws -> SqliteDatabase {
        let db = try openExisting(atPath: atPath)
        try db.createTable(table: Reflection.self)
        return db
    }
    
    // Safely get last recorded sqlite3_errmsg
    public var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            return String(cString: errorPointer)
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    // Prepare a sql statement
    func prepare(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SqliteError.Prepare(message: errorMessage)
        }
        return statement
    }
    
    // Create a sql table
    func createTable(table: SqlTable.Type) throws {
        let stmt = try prepare(sql: table.createStatement)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
}

