// Wayfinder

import Foundation

enum SqliteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    case Unspecified(message: String)
}

class SqliteDatabase {
    
    private let dbPointer: OpaquePointer? // C pointer
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    /// Sqlite3 user version is stored as a 32 bit integer I think
    static var version: Int32 = 0
    
    /// Open a database connection to a transient in memory database (generally for testing or migrating)
    static func openInMemory() throws -> SqliteDatabase {
        return try open(at: URL(string: "file::memory:")!)
    }
    
    /// Open database connection. Creates tables or migrate as needed.
    static func open(at url: URL) throws -> SqliteDatabase {
        
        // Is this a new file?
        let isNewFile = !FileManager.default.fileExists(atPath: url.path)
        
        // Open the connection
        let db = try openDatabase(at: url.absoluteString)
        
        // If this is a new file, create the initial tables
        if isNewFile {
            try db.createTable(table: Reflection.self)
        }
        
        // Get current version
        let dbVersion = db.version
        
        // Sanity checks
        if dbVersion > version {
            fatalError("Cannot migrate database backwards! Database at path \(url) has version \(dbVersion), while the application is only version \(version)")
        }
        
        // Nothing to do if this is the correct version
        if dbVersion == version {
            return db
        }
        
        // Migrate database to current version
        for stepVersion in dbVersion...version {
            switch stepVersion {
            case 0:
                // Migrate 0 --> 1
                break
            default:
                // No schema changes
                break
            }
        }
        
        while db.version < version {
            
            db.version += 1
        }
        
        return db
    }
    
    /// Open a database file. File does not need to exist
    private static func openDatabase(at path: String) throws -> SqliteDatabase {
        
        // Attempt to open database
        var db: OpaquePointer?
        
        // Return database if possible
        if sqlite3_open(path, &db) == SQLITE_OK {
            return SqliteDatabase(dbPointer: db)
        }
        
        // There must be some problem.
        // Clean up database if possible when this closure goes out of scope
        defer {
            if db != nil {
                sqlite3_close(db)
            }
        }
        
        // Attempt to report error message
        var message: String
        if let errorPointer = sqlite3_errmsg(db) {
            message = String(cString: errorPointer)
        } else {
            message = "No error message provided from sqlite."
        }
        throw SqliteError.OpenDatabase(message: message)
    }
    
    /// Safely get last recorded sqlite3_errmsg
    public var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            return String(cString: errorPointer)
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    /// Prepare a sql statement
    func prepare(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SqliteError.Prepare(message: errorMessage)
        }
        return statement
    }
    
    /// Create a sql table
    func createTable(table: SqlTable.Type) throws {
        let stmt = try prepare(sql: table.createStatement)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    /// Get the last inserted rowid
    func lastInsertedRowId() -> Int64 {
        return sqlite3_last_insert_rowid(dbPointer)
    }
    
    /// The database version
    var version: Int32 {
        get {
            let stmt = try! prepare(sql: "PRAGMA user_version;")
            defer {
                sqlite3_finalize(stmt)
            }
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                fatalError("Could not read database version: \(errorMessage)")
            }
            return sqlite3_column_int(stmt, 0)
        }
        set(newVersion) {
            // Prepare seems to fail with "?" involved
            let stmt = try! prepare(sql: "PRAGMA user_version = \(newVersion);")
            defer {
                sqlite3_finalize(stmt)
            }
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                fatalError("Could not set database version to \(newVersion): \(errorMessage)")
            }
        }
    }
}

