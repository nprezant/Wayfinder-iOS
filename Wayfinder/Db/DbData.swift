// Wayfinder

import Foundation

class DbData: ObservableObject {
    private static var documentsFolder: URL {
        do {
            return try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)
        } catch {
            fatalError("Can't find documents directory.")
        }
    }
    private static var fileURL: URL {
        return documentsFolder.appendingPathComponent("wayfinder.sqlite3")
    }
    @Published var reflections: [Reflection] = []
    
    private var db: SqliteDatabase
    
    public init() {
        do {
            try db = SqliteDatabase.open(atPath: DbData.fileURL)
        } catch {
            fatalError("Cannot open database: \(DbData.fileURL)")
        }
    }

    func loadReflections() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let reflections = self?.db.reflections() else {
                fatalError("Can't read saved reflection data.")
            }
            DispatchQueue.main.async {
                self?.reflections = reflections
            }
        }
    }
    
    func saveReflection(reflection: Reflection) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.insertReflection(reflection: reflection)
            } catch {
                fatalError("Can't insert reflection data")
            }
        }
    }
}

