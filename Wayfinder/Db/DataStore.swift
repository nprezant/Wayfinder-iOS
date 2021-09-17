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
            try s.write(to: DataStore.exportUrl, atomically: true, encoding: .utf8)
        } catch let e {
            fatalError("Can't write to csv export file at \(DataStore.exportUrl). Error: \(e)")
        }
        
        return DataStore.exportUrl;
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

extension Date {
    var plusOneWeek: Date {
        return Calendar.current.date(byAdding: .day, value: 7, to: self)!
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    func dayIsBetween(_ date1: Date, and date2: Date) -> Bool {
        return (min(date1, date2).startOfDay ... max(date1, date2).endOfDay).contains(self)
    }
}