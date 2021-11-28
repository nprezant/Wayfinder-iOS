// Wayfinder

import Foundation
import os

struct PreferencesData: Codable {
    var activeAxis: String = "Work"
}

class Preferences {
    var data: PreferencesData
    
    init(data: PreferencesData) {
        self.data = data
    }
    
    private static var fileUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("preferences.json")
    }
    
    func load(_ completion: @escaping (PreferencesData)->Void = {_ in }) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let data = try? Data(contentsOf: Self.fileUrl) else {
                Logger().info("Preferences file does not exist: \(Self.fileUrl)")
                return
            }
            guard let preferences = try? JSONDecoder().decode(PreferencesData.self, from: data) else {
                fatalError("Can't decode preferences file.")
            }
            DispatchQueue.main.async {
                self?.data = preferences
                completion(preferences)
            }
        }
    }
    
    func save() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let activeAxis = self?.data.activeAxis else { fatalError("Self out of scope") }
            let preferencesData = PreferencesData(activeAxis: activeAxis)
            guard let data = try? JSONEncoder().encode(preferencesData) else { fatalError("Error encoding preferences data") }
            do {
                try data.write(to: Self.fileUrl)
            } catch {
                fatalError("Can't write to file")
            }
        }
    }
}
