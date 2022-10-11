// Wayfinder

import Foundation
import Combine
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

class Store: ObservableObject {
    private static var dbUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("wayfinder.sqlite3")
    }
    
    private static var exportUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("wayfinder.csv")
    }
    
    /// Reflections on the current axis
    @Published var reflections: [Reflection] = []
    
    /// Activity names on the current axis
    @Published var activityNames: [String] = []
    
    /// Tag names on the current axis
    @Published var tagNames: [String] = []
    
    /// All tag names
    @Published var allTagNames: [String] = []
    
    /// All visible axes
    @Published var visibleAxes: [Axis] = []
    
    /// All hidden axes
    @Published var hiddenAxes: [Axis] = []
    
    /// The currently active axis
    @Published var activeAxis: String = ""
    
    /// The wrapped database
    private var db: SqliteDatabase
    
    /// Can only have one sync happening at a time
    private var isSyncing: Bool = false
    
    public init(inMemory: Bool = false) {
        do {
            try db = inMemory ? SqliteDatabase.openInMemory() : SqliteDatabase.open(at: Store.dbUrl)
        } catch let e {
            // TODO not sure how to make this recoverable...
            fatalError("Cannot open database: \(Store.dbUrl). Error: \(e)")
        }
    }
        
    public static func createExample() -> Store {
        let store = Store(inMemory: true)
        for r in Reflection.exampleData {
            do {
                let _ = try store.db.insert(reflection: r)
            } catch {
                Logger().error("Could not insert example reflection data. \(store.db.errorMessage)")
            }
        }
        do {
            store.reflections = try store.db.fetchReflections()
        } catch {
            Logger().error("Could not fetch example reflections. \(store.db.errorMessage)")
        }
        return store
    }
    
    /// Performs initial sync with persistant data, including preferences and database (asyncronosly)
    public func syncInitial() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            Logger().info("Initial sync")
            
            let preferences = PreferencesData.load()
            
            if let preferences = preferences {
                // Only apply preferences if they exist
                // Syncing with an axis has the side effect of also updating the active axis
                self.sync(withAxis: preferences.activeAxis)
            } else {
                // Use default preferences
                self.sync(withAxis: PreferencesData().activeAxis)
            }
        }
    }
    
    /// Saves preferences (asyncronosly)
    public func savePreferences() {
        PreferencesData(activeAxis: activeAxis).save()
    }
    
    /// Syncs published properties with the database (asyncronosly)
    public func sync(withAxis: String? = nil, _ completion: @escaping ()->Void = {}) {
        if isSyncing {
            Logger().warning("Cannot begin a sync while another sync is incomplete")
            completion()
            return
        }
        isSyncing = true
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let axis = withAxis ?? self.activeAxis
            Logger().info("Syncing with axis = \(axis)")
            do {
                let reflections = try self.db.fetchReflections(axis: axis)
                let activityNames = try self.db.fetchVisibleActivities(axis: axis)
                let allTagNames = try self.db.fetchUniqueTagNames().sorted(by: <)
                let tagNames = try self.db.fetchUniqueTagNames(axis: axis).sorted(by: <)
                let axes = try self.db.fetchAllAxes().sorted(by: { $0.name < $1.name })
                let visibleAxes = axes.filter{ !$0.hidden.boolValue }
                let hiddenAxes = axes.filter{ $0.hidden.boolValue }
                
                // Assigning published properties is UI work, must do on main thread
                DispatchQueue.main.async {
                    self.activeAxis = axis
                    self.reflections = reflections
                    self.activityNames = activityNames
                    self.allTagNames = allTagNames
                    self.tagNames = tagNames
                    self.visibleAxes = visibleAxes
                    self.hiddenAxes = hiddenAxes
                    completion()
                }
            } catch {
                let msg = "\(error)"
                Logger().error("Sync error: \(msg)")
                completion()
            }
            self.isSyncing = false
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
        Logger().info("Processing batch renames")
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
            
            Logger().info("Adding reflection \(reflection)")
            
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
            do {
                let dbId = try self.db.insert(reflection: reflections[i])
                reflections[i].id = dbId
                self.reflections.append(reflections[i])
            } catch {
                Logger().error("Could not add reflection \(self.db.errorMessage)")
            }
        }
    }
    
    /// Adds a single new axis.
    func add(axis: String, completion: @escaping (SqliteError?)->()) {
        
        // Database logic on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            
            guard let self = self else { return }
            
            Logger().info("Adding axis \(axis)")
            
            var result: SqliteError?
            
            do {
                try self.db.insert(axis: axis)
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
            Logger().info("Updating reflection \(reflection)")
            do {
                try self.processPendingBatchRenames()
                try self.db.update(reflection: reflection)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                DispatchQueue.main.async {
                    completion(e)
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(SqliteError.Unspecified(message: "\(e)"))
                }
            }
        }
    }
    
    /// Updates the axis with the matching ID to contain new data
    func update(axis: Axis, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            Logger().info("Updating axis \(axis)")
            do {
                try self.db.update(axis: axis)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                DispatchQueue.main.async {
                    completion(e)
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(SqliteError.Unspecified(message: "\(e)"))
                }
            }
        }
    }
    
    /// Delete reflections based on database id
    func delete(reflectionIds: [Int64], completion: @escaping (SqliteError?)->() = {_ in}) {
        self.reflections.removeAll(where: {reflectionIds.contains($0.id)})
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            Logger().info("Deleting reflections \(reflectionIds.map{"\($0)"}.joined(separator: ", "))")
            do {
                try self.processPendingBatchRenames()
                try self.db.delete(reflectionsIds: reflectionIds)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                DispatchQueue.main.async {
                    completion(e)
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(SqliteError.Unspecified(message: "\(e)"))
                }
            }
        }
    }
    
    /// Delete axes
    func delete(axes: [String], completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            Logger().info("Deleting axes \(axes.joined(separator: ", "))")
            do {
                try self.db.delete(axes: axes)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                DispatchQueue.main.async {
                    completion(e)
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(SqliteError.Unspecified(message: "\(e)"))
                }
            }
        }
    }
    
    /// Merge axes
    func merge(axis: Axis, into: Axis, completion: @escaping (SqliteError?)->() = {_ in}) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            Logger().info("Merging axis \(axis) into \(into)")
            do {
                try self.db.merge(axis: axis, into: into)
                self.sync() {
                    completion(nil)
                }
            } catch let e as SqliteError {
                DispatchQueue.main.async {
                    completion(e)
                }
            } catch let e {
                DispatchQueue.main.async {
                    completion(SqliteError.Unspecified(message: "\(e)"))
                }
            }
        }
    }
    
    private struct ExportHeader: Encodable, Decodable {
        var schemaVersion: Int32
        
        func toJson() -> String {
            guard let data = try? JSONEncoder().encode(self) else {
                Logger().warning("Error encoding export header data")
                return ""
            }
            return String(decoding: data, as: UTF8.self)
        }
        
        static func fromJson(_ data: Data) throws -> ExportHeader {
            guard let exportHeader = try? JSONDecoder().decode(ExportHeader.self, from: data) else {
                throw SqliteError.Unspecified(message: "Can't decode json export header data: \(String(decoding: data, as: UTF8.self))")
            }
            return exportHeader
        }
    }
    
    func exportCsv(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            Logger().info("Exporting csv")
            let reflections: [Reflection]
            do {
                reflections = try self.db.fetchReflections()
            } catch {
                let msg = "\(error)"
                Logger().error("Could not fetch current reflections for export. Using last fetched reflections. Error: \(msg)")
                reflections = self.reflections
            }
            
            var s: String = "\(ExportHeader(schemaVersion: self.db.version).toJson())\n"
            s += "view\tname\tisFlowState\tengagement\tenergy\tdate\tnote\ttags\n"
            
            for r in reflections {
                s.append("\(r.axis)\t\(r.name)\t\(r.isFlowState)\t\(r.engagement)\t\(r.energy)\t\(r.date)\t\(r.note)\t\(r.tags.joined(separator: ";"))\n")
            }
            
            var result: Result<URL, Error>
            
            do {
                try s.write(to: Store.exportUrl, atomically: true, encoding: .utf8)
                result = .success(Store.exportUrl)
            } catch let e {
                result = .failure(SqliteError.Unspecified(message: "Can't write to csv export file at \(Store.exportUrl). Error: \(e)"))
            }
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    func importCsvAsync(fileURL: URL, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var result: Error? = nil
            do {
                try self.importCsv(fileURL: fileURL)
            } catch {
                result = error
            }
            
            self.sync() {
                completion(result)
            }
        }
    }
    
    func importCsv(fileURL: URL) throws {
        // Log a nice note
        Logger().info("Reading url: \(fileURL)")
        
        // Read file
        let data = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = data.components(separatedBy: .newlines)
        if lines.isEmpty {
            throw SqliteError.Unspecified(message: "File is empty; no data imported.")
        }
        
        Logger().debug("\(data)")
        
        // Read headers
        guard let exportHeaderData = lines[0].data(using: .utf8) else { throw SqliteError.Unspecified(message: "Cannot convert export header string to data") }
        let exportHeader = try ExportHeader.fromJson(exportHeaderData)
        
        // Different import logic for different schema versions
        let schemaVersion = exportHeader.schemaVersion
        
        // Make sure there is at least one record. First two lines are export headers and column headers
        // so there must be 3 or more total lines for data to exist. Having 2 lines is acceptable, just no data will be read.
        if lines.count < 2 {
            throw SqliteError.Unspecified(message: "Cannot import data. Found \(lines.count) lines in import file. Expected at least 2.")
        }
        
        // Wrap this whole fiasco in a transaction so as to avoid making changes when one buggers out
        try db.beginTransaction()
        defer { try! db.endTransaction() }
        
        // Go line by line. Skip header lines.
        for line in lines[2..<lines.count] {
            
            // Skip blank lines
            if line.trimmingCharacters(in: .whitespaces) == "" {
                continue
            }
            
            // Different schemas have different export formats
            switch schemaVersion {
            case 3:
                let tokens = line.components(separatedBy: "\t")
                if tokens.count != 8 { throw SqliteError.Unspecified(message: "Expected 8 tab delimited items, got \(tokens.count) on line: \(line)") }
                let view = tokens[0]
                let name = tokens[1]
                guard let isFlowState = Int64(tokens[2]) else { throw SqliteError.Unspecified(message: "Cannot convert isFlowState to int: \(tokens[2])") }
                guard let engagement = Int64(tokens[3]) else { throw SqliteError.Unspecified(message: "Cannot convert engagement to int: \(tokens[3])") }
                guard let energy = Int64(tokens[4]) else { throw SqliteError.Unspecified(message: "Cannot convert energy to int: \(tokens[4])") }
                guard let date = Int64(tokens[5]) else { throw SqliteError.Unspecified(message: "Cannot convert date to int: \(tokens[5])") }
                let note = tokens[6]
                let tags = tokens[7].components(separatedBy: ";")
                let _ = try db.insert(reflection: Reflection(id: 0, name: name, isFlowState: isFlowState, engagement: engagement, energy: energy, date: date, note: note, axis: view, tags: tags))
            default:
                throw SqliteError.Unspecified(message: "Unsupported schema version: \(schemaVersion)")
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
            Logger().info("Generating averaged report")
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
            Logger().info("Generating best of report")
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
            Logger().info("Generating best of all report")
            
            var categoryValues: [String] = []
            
            switch category {
            case .activity:
                categoryValues = self.activityNames
            case .tag:
                categoryValues = self.allTagNames
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
