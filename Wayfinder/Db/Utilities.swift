// Wayfinder

import Foundation

extension Date {
    var plusOneWeek: Date {
        return Calendar.current.date(byAdding: .day, value: 7, to: self)!
    }
    var minusOneWeek: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: self)!
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

extension Bool {
    var intValue: Int64 { self ? 1 : 0 }
}

extension Int64 {
    var boolValue: Bool {
        return self != 0
    }
}

struct FileLocations {
    public static var documentsFolder: URL {
        // Apple's eskimo says this try! is okay
        return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}
