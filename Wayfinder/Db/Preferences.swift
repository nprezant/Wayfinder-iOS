// Wayfinder

import Foundation
import os

struct PreferencesData: Codable {
    var activeAxis: String = "Work"
}

extension PreferencesData {    
    private static var fileUrl: URL {
        return FileLocations.documentsFolder.appendingPathComponent("preferences.json")
    }
    
    static func load() -> PreferencesData? {
        guard let data = try? Data(contentsOf: Self.fileUrl) else {
            Logger().info("Preferences file does not exist: \(Self.fileUrl)")
            return nil
        }
        guard let preferences = try? JSONDecoder().decode(PreferencesData.self, from: data) else {
            Logger().warning("Can't decode preferences file: \(Self.fileUrl)")
            return nil
        }
        return preferences
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else {
            Logger().warning("Error encoding preferences data")
            return
        }
        do {
            try data.write(to: Self.fileUrl)
        } catch {
            Logger().warning("Cannot write to preferences data file: \(Self.fileUrl)")
        }
    }
}
