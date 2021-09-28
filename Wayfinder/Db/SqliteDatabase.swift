// Wayfinder

import Foundation

enum SqliteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    case Unspecified(message: String)
}

// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Statement.swift#L179
// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Database.swift#L14
let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

protocol SqlTable {
    static var createStatement: String { get }
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
    static var latestVersion: Int32 = 0
    
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
        if dbVersion > latestVersion {
            fatalError("Cannot migrate database backwards! Database at path \(url) has version \(dbVersion), while the latest version is only \(latestVersion)")
        }
        
        // Nothing to do if this is the correct version
        if dbVersion == latestVersion {
            return db
        }
        
        // This is an old database version and it needs to be migrated. Save yourself a backup.
        if !isNewFile {
            try FileManager.default.copyItem(at: url, to: url.appendingPathExtension(".before-migration"))
        }
        
        // Migrate database to current version
        for stepVersion in dbVersion...latestVersion {
            switch stepVersion {
            case 0:
                // Migrate 0 --> 1
                try db.createTable(table: Tag.self)
                db.version = 1
                break
            default:
                // No schema changes
                break
            }
        }
        
        return db
    }
    
    /// Open a database file. File does not need to exist
    private static func openDatabase(at path: String) throws -> SqliteDatabase {
        
        var dbPointer: OpaquePointer?
        
        // Attempt to open the database connection
        if sqlite3_open(path, &dbPointer) == SQLITE_OK {
            
            // Wrap C pointer
            let db = SqliteDatabase(dbPointer: dbPointer)
            
            // Enable foreign keys. Required for each connection.
            try db.enableForeignKeys()
            
            return db
        }
        
        // There must be some problem.
        // Clean up database if possible when this closure goes out of scope
        defer {
            if dbPointer != nil {
                sqlite3_close(dbPointer)
            }
        }
        
        // Attempt to report error message
        var message: String
        if let errorPointer = sqlite3_errmsg(dbPointer) {
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
    
    private func enableForeignKeys() throws {
        let stmt = try prepare(sql: "PRAGMA foreign_keys = ON;")
        defer {
            sqlite3_finalize(stmt)
        }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: "Could not enable foreign keys: \(errorMessage)")
        }
    }
    
    private var filepath: String? {
        get {
            guard let filenamePtr = sqlite3_db_filename(dbPointer, "main") else { return nil }
            return String(cString: filenamePtr)
        }
    }
    
    var tableSchemas: [String] {
        get {
            let stmt = try! prepare(sql: "SELECT sql FROM sqlite_master;")
            defer {
                sqlite3_finalize(stmt)
            }
            var tableSchemas: [String] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let tableSchema = String(cString: sqlite3_column_text(stmt, 0))
                tableSchemas.append(tableSchema)
            }
            return tableSchemas
        }
    }
}

