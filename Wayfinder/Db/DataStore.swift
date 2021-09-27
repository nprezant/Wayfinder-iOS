// Wayfinder

import Foundation

class DataStore: ObservableObject {
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
    
    @Published var reflections: [Reflection] = [] {
        didSet {
            uniqueReflectionNames = Array(Set(reflections.map{$0.name})).sorted(by: <)
        }
    }
    
    @Published var uniqueReflectionNames: [String] = []
    
    private var db: SqliteDatabase
    
    public init(inMemory: Bool = false) {
        do {
            try db = inMemory ? SqliteDatabase.openInMemory() : SqliteDatabase.open(at: DataStore.dbUrl)
        } catch {
            fatalError("Cannot open database: \(DataStore.dbUrl)")
        }
    }
    
    public static func createExample() -> DataStore {
        let dataStore = DataStore(inMemory: true)
        for r in Reflection.exampleData {
            do {
                let _ = try dataStore.db.insert(reflection: r)
            } catch {
                fatalError("Could not create example data. \(dataStore.db.errorMessage)")
            }
        }
        dataStore.reflections = dataStore.db.reflections()
        return dataStore
    }

    // Read the database on the background thread
    // `reflections` property is updated automatically
    func loadReflections(_ completion: @escaping ([Reflection])->() = {_ in }) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            let reflections = self.db.reflections()
            
            // Do any UI work on the main thread
            DispatchQueue.main.async {
                self.reflections = reflections
                completion(reflections)
            }
        }
    }
    
    // Returns the new inserted ID.
    // No action necessary with the ID; the data store list is updated automatically
    func add(reflection: Reflection, completion: @escaping (Result<Int64, SqliteError>)->()) {
        
        // The default id is 0, and will be re-assigned when it is inserted into the database
        // After the data is inserted into the database, that insertion id needs to be pushed back to the list in memory
        // To find this reflection in memory, we give it a unique id
        let uniqueId = self.nextUniqueReflectionId()
        var reflection = reflection // Make modifyable copy
        reflection.id = uniqueId
        
        // Add data to the list shown in the UI
        self.reflections.append(reflection)
        self.reflections.sort(by: {$0.date > $1.date})
        
        // Database logic on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            
            var result: Result<Int64, SqliteError>
            
            // Database assigns a new id on insert
            var dbId: Int64?
            do {
                dbId = try self!.db.insert(reflection: reflection)
                result = .success(dbId!)
            } catch let e as SqliteError {
                result = .failure(e)
            } catch let e {
                result = .failure(SqliteError.Unspecified(message: "Can't add reflection data. \(e)"))
            }
            
            // Any UI logic must be done on main thread
            DispatchQueue.main.async {
                if let unwrappedDbId = dbId {
                    // Reflection was properly inserted so the database assigned id needs to be applied to the in memory UI list
                    let location = self!.reflections.firstIndex(where: {$0.id == uniqueId})
                    self!.reflections[location!].id = unwrappedDbId
                }
                completion(result)
            }
        }
    }
    
    // Adds many reflections (not async...) and updates the ids to match the those in the inserted database
    func add(reflections: inout [Reflection]) {
        for i in reflections.indices {
            let dbId = try! self.db.insert(reflection: reflections[i])
            reflections[i].id = dbId
            self.reflections.append(reflections[i])
        }
    }
    
    // Updates the reflection with the matching ID to contain new data
    func update(reflection: Reflection, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.update(reflection: reflection)
                completion(nil)
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: e.localizedDescription))
            }
        }
    }
    
    func delete(reflectionIds: [Int64], completion: @escaping (SqliteError?)->() = {_ in}) {
        self.reflections.removeAll(where: {reflectionIds.contains($0.id)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            do {
                try self?.db.delete(reflectionsIds: reflectionIds)
                completion(nil)
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: e.localizedDescription))
            }
        }
    }
    
    func ExportCsv(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            let reflections = self!.db.reflections()
            
            var s: String = "name\tisFlowState\tengagement\tenergy\tdate\tnote\n"
            
            for r in reflections {
                s.append("\(r.name)\t\(r.isFlowState)\t\(r.engagement)\t\(r.energy)\t\(r.date)\t\(r.note)\n")
            }
            
            var result: Result<URL, Error>
            
            do {
                try s.write(to: DataStore.exportUrl, atomically: true, encoding: .utf8)
                result = .success(DataStore.exportUrl)
            } catch let e {
                result = .failure("Can't write to csv export file at \(DataStore.exportUrl). Error: \(e)" as! Error) // TODO not sure this cast is safe...
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func nextUniqueReflectionId() -> Int64 {
        if self.reflections.isEmpty {
            return 1
        }
        return self.reflections.map{$0.id}.max()! + 1 // max() returns nil if array is empty
    }
    
    func makeAverageReport(for date: Date, completion: @escaping (Result<Reflection.Averaged?, Error>) -> Void) {
        let requestedDateComponents = Calendar.current.dateComponents([.day, .year], from: date)
        makeAverageReport({Calendar.current.dateComponents([.day, .year], from: $0.data.date) == requestedDateComponents}, completion: completion)
    }
    
    func makeAverageReport(for start: Date, to end: Date, completion: @escaping (Result<Reflection.Averaged?, Error>) -> Void) {
        makeAverageReport({$0.data.date.dayIsBetween(start, and: end)}, completion: completion)
    }
    
    func makeAverageReport(forName: String, completion: @escaping (Result<Reflection.Averaged?, Error>) -> Void) {
        makeAverageReport({$0.name == forName}, completion: completion)
    }
    
    private func makeAverageReport(_ isIncluded: @escaping (Reflection) -> Bool, completion: @escaping (Result<Reflection.Averaged?, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard (self != nil) else { fatalError("Self out of scope") }
            let relevantReflections = self!.reflections.filter{isIncluded($0)}
            let result = Reflection.Averaged.make(from: relevantReflections)
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
}
