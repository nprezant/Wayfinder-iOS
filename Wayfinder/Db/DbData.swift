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
    private static var dbUrl: URL {
        return documentsFolder.appendingPathComponent("wayfinder.sqlite3")
    }
    
    private static var exportUrl: URL {
        return documentsFolder.appendingPathComponent("wayfinder.csv")
    }
    
    @Published var reflections: [Reflection] = []
    
    private var db: SqliteDatabase
    
    public init(inMemory: Bool = false) {
        let p = inMemory ? URL(string: "file::memory:")! : DbData.dbUrl
        do {
            try db = SqliteDatabase.open(at: p)
        } catch {
            fatalError("Cannot open database: \(DbData.dbUrl)")
        }
    }
    
    public static func createExample() -> DbData {
        let dbData = DbData(inMemory: true)
        for r in Reflection.exampleData {
            do {
                let _ = try dbData.db.insert(reflection: r)
            } catch {
                fatalError("Could not create example data. \(dbData.db.errorMessage)")
            }
        }
        dbData.reflections = dbData.db.reflections()
        return dbData
    }

    func loadReflections() {
        // Read the database on the background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let reflections = self?.db.reflections() else {
                fatalError("Can't read saved reflection data.")
            }
            
            // Do any UI work on the main thread
            DispatchQueue.main.async {
                self?.reflections = reflections
            }
        }
    }
    
    // TODO handle async better... perhaps with Result<T>... completion: @escaping (Result<Any, SqliteError>)->())  {
    func saveReflection(reflection: Reflection) {
        self.reflections.append(reflection)
        self.reflections.sort(by: {$0.date > $1.date})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            
            // Database assigns a new id on insert
            var dbId: Int64?
            do {
                dbId = try self?.db.insert(reflection: reflection)
            } catch {
                fatalError("Can't insert reflection data. \(self?.db.errorMessage ?? "No db message provided")")
            }
            
            // Update the last inserted reflection to use the database assigned id
            DispatchQueue.main.async {
                let location = self?.reflections.firstIndex(where: {$0.id == reflection.id})
                self?.reflections[location!].id = dbId!
            }
        }
    }
    
    func update(reflection: Reflection) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.update(reflection: reflection)
            } catch {
                fatalError("Can't update reflection data. \(self?.db.errorMessage ?? "No db message provided")")
            }
        }
    }
    
    func delete(reflectionIds: [Int64]) {
        self.reflections.removeAll(where: {reflectionIds.contains($0.id)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.delete(reflectionsIds: reflectionIds)
            } catch {
                fatalError("Can't delete reflection data. \(self?.db.errorMessage ?? "No db message provided")")
            }
        }
    }
    
    func ExportCsv() -> URL {
        let reflections = self.db.reflections()
        
        var s: String = "name\tisFlowState\tengagement\tenergy\tdate\tnote\n"
        
        for r in reflections {
            s.append("\(r.name)\t\(r.isFlowState)\t\(r.engagement)\t\(r.energy)\t\(r.date)\t\(r.note)\n")
        }
        
        do {
            try s.write(to: DbData.exportUrl, atomically: true, encoding: .utf8)
        } catch let e {
            fatalError("Can't write to csv export file at \(DbData.exportUrl). Error: \(e)")
        }
        
        return DbData.exportUrl;
    }
    
    func nextUniqueReflectionId() -> Int64 {
        if self.reflections.isEmpty {
            return 1
        }
        return self.reflections.map{$0.id}.max()! + 1 // max() returns nil if array is empty
    }
}

