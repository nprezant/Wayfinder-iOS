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

/// General interface to a SQLite database. Provides general usage functions.
class SqliteDatabase {
    
    private let dbPointer: OpaquePointer? // C pointer
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    /// Sqlite3 user version is stored as a 32 bit integer
    static var latestVersion: Int32 = 3
    
    /// Open a database connection to a transient in memory database (generally for testing or migrating)
    static func openInMemory(targetVersion: Int32 = latestVersion) throws -> SqliteDatabase {
        return try open(at: URL(string: "file::memory:")!, targetVersion: targetVersion)
    }
    
    /// Open database connection. Creates tables or migrate as needed.
    static func open(at url: URL, targetVersion: Int32 = latestVersion) throws -> SqliteDatabase {
        
        // Very helpful informatino to log
        Logger().info("Database path: \(url.absoluteString)")
        
        // Is this a new file?
        let isNewFile = !FileManager.default.fileExists(atPath: url.path)
        
        // Open the connection
        let db = try openDatabase(at: url.absoluteString)
        
        // Nothing to do if this is the correct version
        if db.version == targetVersion {
            return db
        }
        
        // This is an old database version and it needs to be migrated. Save yourself a backup.
        if !isNewFile {
            let backupUrl = url.appendingPathExtension("before-migration")
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

        // Whichever direction we are going, we don't want to duplicate that version's migrator
        let startAtVersion = goingUp ? version + 1 : version - 1
        
        // Migrate database to current version
        for stepVersion in stride(from: startAtVersion, through: targetVersion, by: goingUp ? 1 : -1) {
            try migrateWithFile(to: stepVersion, goingUp: goingUp)
            version = stepVersion
        }
    }
    
    private let migrationFiles: [Int32:String] = [
        1: "001-initial",
        2: "002-tags",
        3: "003-axis",
    ]
    
    /// Runs a migration file. Can either run up or down.
    private func migrateWithFile(to targetVersion: Int32, goingUp: Bool) throws {
        
        // The actual file we need depends on if we are going up or down.
        // If we are going up, we want to migrate up to that version, so we use the 'up' of that version directly
        // If we are going down, we want to undo the previously applied version, so we use the 'down' of the next version
        guard let fileName = migrationFiles[goingUp ? targetVersion : targetVersion + 1] else {
            throw SqliteError.Migrate(message: "No migrator file associated with version \(targetVersion)")
        }
        
        guard let thisMigratorFile = Bundle.main.url(forResource: fileName, withExtension: "sqlite3") else {
            throw SqliteError.Migrate(message: "Cannot find migrator file! Expected: \(fileName)")
        }

        Logger().info("Migrating \(goingUp ? "up" : "down") to version \(targetVersion) with file: \(thisMigratorFile.lastPathComponent)")
        
        let migrator = try Migrator.open(url: thisMigratorFile)
        
        if goingUp {
            try executeMany(sql: migrator.sqlUp)
        } else {
            try executeMany(sql: migrator.sqlDown)
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
    func execute(sql: String, binds: Int64...) throws {
        guard sql.split(separator: ";").count == 1 else {
            throw SqliteError.Unspecified(message: "Cannot `execute` sql statement contains multiple commands. Please use `executeMany` to run multiple commands")
        }
        let stmt = try prepare(sql: sql)
        defer {
            sqlite3_finalize(stmt)
        }
        
        for (n, bindItem) in binds.enumerated() {
            guard
                sqlite3_bind_int64(stmt, Int32(n + 1), bindItem) == SQLITE_OK
            else {
                throw SqliteError.Bind(message: errorMessage)
            }
        }
        
        let rc = sqlite3_step(stmt)
        
        guard [SQLITE_DONE, SQLITE_OK].contains(rc) else {
            throw SqliteError.Step(message: "Statement \(sql) returned \(rc) with message: \(errorMessage)")
        }
    }
    
    /// Execute many sql commands
    func executeMany(sql: String) throws {
        // Remove comment lines and split into commands
        // TODO note this doesn't handle /* */ C style comments
        let lines = sql.split(separator: "\n")
        let linesWithoutComments = lines.filter{ !$0.trimmingCharacters(in: .whitespaces).starts(with: "--") }
        let commands = linesWithoutComments.joined(separator: "\n").split(separator: ";")
        
        for command in commands {
            try execute(sql: String(command))
        }
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
        get throws {
            let sql = """
                SELECT
                    name
                FROM
                    sqlite_master
                WHERE
                    type ='table' AND
                    name NOT LIKE 'sqlite_%';
            """
            let stmt = try prepare(sql: sql)
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
        guard try tableNames.contains(name) else {
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
            let stmt: OpaquePointer?
            do {
                stmt = try prepare(sql: "PRAGMA user_version;")
            } catch {
                let msg = "\(error)"
                Logger().error("Could not read user_version. Assuming 0. \(msg)")
                return 0
            }
            defer {
                sqlite3_finalize(stmt)
            }
            guard sqlite3_step(stmt) == SQLITE_ROW else {
                Logger().error("Could not read database version. Assuming 0. \(self.errorMessage)")
                return 0
            }
            return sqlite3_column_int(stmt, 0)
        }
        set(newVersion) {
            let stmt: OpaquePointer?
            do {
                // Prepare seems to fail with "?" involved
                stmt = try prepare(sql: "PRAGMA user_version = \(newVersion);")
            } catch {
                let msg = "\(error)"
                Logger().error("Could not set user_version. \(msg)")
                return
            }
            defer {
                sqlite3_finalize(stmt)
            }
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                Logger().error("Could not set database version to \(newVersion). Version is unchanged. \(self.errorMessage)")
                return
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
        get throws {
            let stmt = try prepare(sql: "SELECT sql FROM sqlite_master;")
            defer {
                sqlite3_finalize(stmt)
            }
            var tableSchemas: [String] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let columnText = sqlite3_column_text(stmt, 0)
                if columnText != nil { // Auto-indexes (e.g. for unique constraints) don't have sql text attached
                    let tableSchema = String(cString: sqlite3_column_text(stmt, 0))
                    tableSchemas.append(tableSchema)
                }
            }
            return tableSchemas
        }
    }
}

