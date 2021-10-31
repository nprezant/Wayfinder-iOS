// Wayfinder

import Foundation
import os

enum SqliteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    case Unspecified(message: String)
    case Migrate(message: String)
}

// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Statement.swift#L179
// https://github.com/groue/GRDB.swift/blob/v2.9.0/GRDB/Core/Database.swift#L14
let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

class SqliteDatabase {
    
    private let dbPointer: OpaquePointer? // C pointer
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    /// Sqlite3 user version is stored as a 32 bit integer I think
    static var latestVersion: Int32 = 1
    
    /// Open a database connection to a transient in memory database (generally for testing or migrating)
    static func openInMemory(targetVersion: Int32 = latestVersion) throws -> SqliteDatabase {
        return try open(at: URL(string: "file::memory:")!, targetVersion: targetVersion)
    }
    
    /// Open database connection. Creates tables or migrate as needed.
    static func open(at url: URL, targetVersion: Int32 = latestVersion) throws -> SqliteDatabase {
        
        // Is this a new file?
        let isNewFile = !FileManager.default.fileExists(atPath: url.path)
        
        // Open the connection
        let db = try openDatabase(at: url.absoluteString)
        
        // If this is a new file, create the initial tables
        if isNewFile {
            try db.execute(sql: Reflection.createStatement)
        }
        
        // Nothing to do if this is the correct version
        if db.version == targetVersion {
            return db
        }
        
        // This is an old database version and it needs to be migrated. Save yourself a backup.
        if !isNewFile {
            let backupUrl = url.appendingPathExtension(".before-migration")
            try? FileManager.default.removeItem(at: backupUrl)
            try FileManager.default.copyItem(at: url, to: backupUrl)
        }
        
        // Migrate database to target version
        try db.migrate(to: targetVersion)
        
        return db
    }
    
    func migrate(to targetVersion: Int32 = latestVersion) throws {
        
        // Nothing to do if this is the current version
        if version == targetVersion {
            return
        }
        
        // Can migrate either up or down
        let goingUp = targetVersion > version ? true : false
        
        // Get the logger
        let logger = Logger()
        
        // Migrate database to current version
        for stepVersion in stride(from: version, through: targetVersion, by: goingUp ? 1 : -1) {
            switch stepVersion {
            case 1:
                if goingUp {
                    // Migrate 0 --> 1
                    logger.info("Migrating 0 to 1")
                    try executeMany(sql: Tag.createStatement)
                    version = 1
                } else {
                    // Migrate 1 --> 0
                    logger.info("Migrating 1 to 0")
                    try executeMany(sql: Tag.dropStatement)
                    version = 0
                }
                break
            default:
                // No schema changes
                break
            }
        }
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
    
    /// Execute sql command
    /// Only executes a single command. Subsequent commands in the string are ignored.
    /// Issues warning if multiple commands are provided.
    func execute(sql: String) throws {
        guard sql.split(separator: ";").count == 1 else {
            throw SqliteError.Unspecified(message: "Cannot `execute` sql statement contains multiple commands. Please use `executeMany` to run multiple commands")
        }
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    /// Execute many sql commands
    func executeMany(sql: String) throws {
        let commands = sql.split(separator: ";")
        try beginTransaction()
        for command in commands {
            try execute(sql: String(command))
        }
        try endTransaction()
    }
    
    /// Begin a transaction
    func beginTransaction() throws {
        try execute(sql: "BEGIN TRANSACTION;")
    }
    
    /// End a transaction
    func endTransaction() throws {
        try execute(sql: "END TRANSACTION;")
    }
    
    /// Create a sql table
    func createTable(sql: String) throws {
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw SqliteError.Step(message: errorMessage)
        }
    }
    
    /// List of all existing tables
    var tableNames: [String] {
        get {
            let sql = """
                SELECT
                    name
                FROM
                    sqlite_master
                WHERE
                    type ='table' AND
                    name NOT LIKE 'sqlite_%';
            """
            let stmt = try! prepare(sql: sql)
            defer {
                sqlite3_finalize(stmt)
            }
            
            var names: [String] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(stmt, 0))
                names.append(name)
            }
            return names
        }
    }
    
    /// Drop a sql table
    /// The sql table name cannot be parameterized using prepare() and bind(), so it is instead sanitized by ensuring beforehand
    /// that the requested table name to drop is indeed a table name in the database
    func dropTable(name: String) throws {
        guard tableNames.contains(name) else {
            throw SqliteError.Prepare(message: "Cannot drop non-existent table '\(name)'")
        }
        let stmt = try prepare(sql: "DROP TABLE \(name);")
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

