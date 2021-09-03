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
        let p = inMemory ? "file::memory:" : DbData.dbUrl.absoluteString
        do {
            try db = SqliteDatabase.open(at: p)
        } catch {
            fatalError("Cannot open database: \(DbData.dbUrl)")
        }
    }
    
    public static func createExample() -> DbData {
        let dbData = DbData(inMemory: true)
        for r in Reflection.exampleData {
//            dbData.saveReflection(reflection: r)
            do {
                try dbData.db.insertReflection(reflection: r)
            } catch {
                fatalError("Could not create example data. \(dbData.db.errorMessage)")
            }
        }
        dbData.reflections = dbData.db.reflections()
        return dbData
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
    
    // TODO handle async better... perhaps with Result<T>... completion: @escaping (Result<Any, SqliteError>)->())  {
    func saveReflection(reflection: Reflection) {
        self.reflections.append(reflection)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.insertReflection(reflection: reflection)
            } catch {
                fatalError("Can't insert reflection data. \(self?.db.errorMessage ?? "No db message provided")")
            }
        }
    }
    
    func updateReflection(reflection: Reflection) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.updateReflection(reflection: reflection)
            } catch {
                fatalError("Can't update reflection data. \(self?.db.errorMessage ?? "No db message provided")")
            }
        }
    }
    
    func delete(reflectionIds: [Int64]) {
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
}

