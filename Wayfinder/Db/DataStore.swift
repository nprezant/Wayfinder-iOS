// Wayfinder

import Foundation
import os

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
    private static var dbUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("wayfinder.sqlite3")
    }
    
    private static var exportUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("wayfinder.csv")
    }
    
    @Published var reflections: [Reflection] = []
    @Published var uniqueReflectionNames: [String] = []
    @Published var uniqueTagNames: [String] = []
    @Published var uniqueAxisNames: [String] = []
    
    @Published var activeAxis: String = PreferencesData().activeAxis
    
    private var db: SqliteDatabase
    
    public init(inMemory: Bool = false) {
        do {
            try db = inMemory ? SqliteDatabase.openInMemory() : SqliteDatabase.open(at: DataStore.dbUrl)
        } catch let e {
            fatalError("Cannot open database: \(DataStore.dbUrl). Error: \(e)")
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
        dataStore.reflections = try! dataStore.db.fetchReflections()
        return dataStore
    }
    
    /// Performs initial sync with persistant data, including preferences and database (asyncronosly)
    public func syncInitial() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            Logger().info("Initial sync")
            
            let preferences = PreferencesData.load()
            
            DispatchQueue.main.async {
                // Only apply preferences if they exists
                if let preferences = preferences {
                    self.activeAxis = preferences.activeAxis
                }
                
                self.sync()
            }
        }
    }
    
    /// Saves preferences (asyncronosly)
    public func savePreferences() {
        PreferencesData(activeAxis: activeAxis).save()
    }
    
    /// Syncs published properties with the database (asyncronosly)
    public func sync(_ completion: @escaping ()->Void = {}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            Logger().info("Syncing")
            
            let reflections = try! self.db.fetchReflections(axis: self.activeAxis)
            let uniqueReflectionNames = Array(Set(reflections.map{$0.name})).sorted(by: <)
            let uniqueTagNames = self.db.fetchAllUniqueTags().sorted(by: <)
            let uniqueAxisNames = self.db.fetchDistinctVisibleAxisNames().sorted(by: <)
            
            // Assigning published properties is UI work, must do on main thread
            DispatchQueue.main.async {
                self.reflections = reflections
                self.uniqueReflectionNames = uniqueReflectionNames
                self.uniqueTagNames = uniqueTagNames
                self.uniqueAxisNames = uniqueAxisNames
                completion()
            }
        }
    }
    
    private var pendingBatchRenames: [BatchRenameData] = []
    
    func enqueueBatchRename(_ data: BatchRenameData) {
        pendingBatchRenames.append(data)
    }
    
    /// Process pending renames. Blocking.
    /// Could consider DispatchGroup
    /// https://stackoverflow.com/questions/42484281/waiting-until-the-task-finishes
    private func processPendingBatchRenames() throws {
        if pendingBatchRenames.isEmpty { return }
        while !pendingBatchRenames.isEmpty {
            let data = pendingBatchRenames.removeFirst()
            try batchRename(with: data)
        }
    }
    
    /// Renames reflections. Blocking.
    private func batchRename(with data: BatchRenameData) throws {
        switch data.category {
        case .activity:
            try db.renameReflections(from: data.oldName, to: data.newName)
        case .tag:
            try db.renameTags(from: data.oldName, to: data.newName)
        }
    }
    
    /// Returns the new inserted ID.
    /// No action necessary with the ID; the data store list is updated automatically
    func add(reflection: Reflection, completion: @escaping (Result<Int64, SqliteError>)->()) {
        
        // Database logic on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            var result: Result<Int64, SqliteError>
            
            // Database assigns a new id on insert
            var dbId: Int64?
            do {
                try self.processPendingBatchRenames()
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
    
    /// Adds a single new axis.
    func add(axis: String, completion: @escaping (SqliteError?)->()) {
        
        // Database logic on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            var result: SqliteError?
            
            do {
                try self.db.createAxis(axis)
            } catch let e as SqliteError {
                result = e
            } catch let e {
                result = SqliteError.Unspecified(message: "Can't add axis '\(axis)'. \(e)")
            }
            
            // Sync app with database
            self.sync() {
                completion(result)
            }
        }
    }
    
    /// Updates the reflection with the matching ID to contain new data
    func update(reflection: Reflection, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.processPendingBatchRenames()
                try self.db.update(reflection: reflection)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: "\(e)"))
            }
        }
    }
    
    /// Delete reflections based on database id
    func delete(reflectionIds: [Int64], completion: @escaping (SqliteError?)->() = {_ in}) {
        self.reflections.removeAll(where: {reflectionIds.contains($0.id)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.processPendingBatchRenames()
                try self.db.delete(reflectionsIds: reflectionIds)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: "\(e)"))
            }
        }
    }
    
    /// Delete axes
    func delete(axes: [String], completion: @escaping (SqliteError?)->() = {_ in}) {
        self.uniqueAxisNames.removeAll(where: {axes.contains($0)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.db.delete(axes: axes)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                completion(e)
            } catch let e {
                completion(SqliteError.Unspecified(message: "\(e)"))
            }
        }
    }
    
    func ExportCsv(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let reflections = try! self.db.fetchReflections()
            
            var s: String = "name\tisFlowState\tengagement\tenergy\tdate\tnote\ttags\n"
            
            for r in reflections {
                s.append("\(r.name)\t\(r.isFlowState)\t\(r.engagement)\t\(r.energy)\t\(r.date)\t\(r.note)\t\(r.tags.joined(separator: ";"))\n")
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
