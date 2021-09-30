// Wayfinder

import Foundation

struct BatchRenameData {
    var category: Category
    var oldName: String
    var newName: String
    
    init(category: Category, from oldName: String, to newName: String) {
        self.category = category
        self.oldName = oldName
        self.newName = newName
    }
}

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
    
    @Published var reflections: [Reflection] = []
    
    @Published var uniqueReflectionNames: [String] = []
    
    @Published var uniqueTagNames: [String] = []
    
    private var db: SqliteDatabase
    
    public init(inMemory: Bool = false) {
        do {
            try db = inMemory ? SqliteDatabase.openInMemory() : SqliteDatabase.open(at: DataStore.dbUrl)
        } catch let e {
            fatalError("Cannot open database: \(DataStore.dbUrl). Error: \(e.localizedDescription)")
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
        dataStore.reflections = dataStore.db.fetchReflections()
        return dataStore
    }
    
    /// Syncs published properties with the database (asyncronosly)
    func sync(_ completion: @escaping ()->Void = {}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            let reflections = self.db.fetchReflections()
            let uniqueReflectionNames = Array(Set(reflections.map{$0.name})).sorted(by: <)
            let uniqueTagNames = self.db.fetchAllUniqueTags().sorted(by: <)
            
            // Assigning published properties is UI work, must do on main thread
            DispatchQueue.main.async {
                self.reflections = reflections
                self.uniqueReflectionNames = uniqueReflectionNames
                self.uniqueTagNames = uniqueTagNames
                completion()
            }
        }
    }
    
    private var pendingBatchRenames: [BatchRenameData] = []
    
    func enqueueBatchRename(_ data: BatchRenameData) {
        pendingBatchRenames.append(data)
    }
    
    /// Process pending renames
    /// TODO be smarter and use DispatchQueue and wait and stuff
    /// https://stackoverflow.com/questions/42484281/waiting-until-the-task-finishes
    private func processPendingBatchRenames(_ completion: @escaping (SqliteError?)->Void = {_ in}) {
        if pendingBatchRenames.isEmpty { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            while !self.pendingBatchRenames.isEmpty {
                
                let data = self.pendingBatchRenames.removeFirst()
                do {
                    switch data.category {
                    case .activity:
                        try self.db.renameReflections(from: data.oldName, to: data.newName)
                    case .tag:
                        try self.db.renameTags(from: data.oldName, to: data.newName)
                    }
                } catch let e as SqliteError {
                    completion(e)
                    return
                } catch let e {
                    completion(SqliteError.Unspecified(message: e.localizedDescription))
                    return
                }
            }
            
            self.sync() {
                completion(nil)
            }
        }
    }
    
    /// Returns the new inserted ID.
    /// No action necessary with the ID; the data store list is updated automatically
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
            
            guard let self = self else { return }
            
            var result: Result<Int64, SqliteError>
            
            // Database assigns a new id on insert
            var dbId: Int64?
            do {
                dbId = try self.db.insert(reflection: reflection)
                result = .success(dbId!)
            } catch let e as SqliteError {
                result = .failure(e)
            } catch let e {
                result = .failure(SqliteError.Unspecified(message: "Can't add reflection data. \(e)"))
            }
            
            // Sync app with database
            self.sync() {
                completion(result)
            }
        }
    }
    
    /// Adds many reflections (not async...) and updates the ids to match the those in the inserted database
    func add(reflections: inout [Reflection]) {
        for i in reflections.indices {
            let dbId = try! self.db.insert(reflection: reflections[i])
            reflections[i].id = dbId
            self.reflections.append(reflections[i])
        }
    }
    
    /// Updates the reflection with the matching ID to contain new data
    func update(reflection: Reflection, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.db.update(reflection: reflection)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: e.localizedDescription))
            }
        }
    }
    
    /// Renames reflections
    private func batchRename(with data: BatchRenameData, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                switch data.category {
                case .activity:
                    try self.db.renameReflections(from: data.oldName, to: data.newName)
                case .tag:
                    try self.db.renameTags(from: data.oldName, to: data.newName)
                }
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: e.localizedDescription))
            }
        }
    }
    
    /// Delete reflections based on database id
    func delete(reflectionIds: [Int64], completion: @escaping (SqliteError?)->() = {_ in}) {
        self.reflections.removeAll(where: {reflectionIds.contains($0.id)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.db.delete(reflectionsIds: reflectionIds)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: e.localizedDescription))
            }
        }
    }
    
    func ExportCsv(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let reflections = self.db.fetchReflections()
            
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
    
    func makeAverageReport(_ isIncluded: @escaping (Reflection) -> Bool, completion: @escaping (Result<Reflection.Averaged?, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let relevantReflections = self.reflections.filter{isIncluded($0)}
            let result = Reflection.Averaged.make(from: relevantReflections)
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
    
    func makeBestOfReport(_ isIncluded: @escaping (Reflection) -> Bool, by metric: Metric, direction bestWorst: BestWorst, completion: @escaping (Result<[Reflection], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let sortComparator = metric.makeComparator(direction: bestWorst)
            let relevantReflections = self.reflections.filter{isIncluded($0)}.sorted(by: sortComparator)
            DispatchQueue.main.async {
                completion(.success(relevantReflections))
            }
        }
    }
    
    func makeBestOfAllReport(for category: Category, by metric: Metric, direction bestWorst: BestWorst, completion: @escaping (Result<[Reflection.Averaged], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var categoryValues: [String] = []
            
            switch category {
            case .activity:
                categoryValues = self.uniqueReflectionNames
            case .tag:
                categoryValues = self.uniqueTagNames
            }
            
            var allAveraged: [Reflection.Averaged] = []
            
            for value in categoryValues {
                let relevantReflections = self.reflections.filter{category.makeInclusionComparator(value)($0)}
                let average = Reflection.Averaged.make(from: relevantReflections, label: value)
                if let unwrappedAverage = average {
                    allAveraged.append(unwrappedAverage)
                }
            }
            
            let sortComparator = metric.makeComparator(direction: bestWorst)
            allAveraged.sort(by: sortComparator)
            
            DispatchQueue.main.async {
                completion(.success(allAveraged))
            }
        }
    }
}
