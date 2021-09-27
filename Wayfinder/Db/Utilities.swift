// Wayfinder

import Foundation

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

extension Bool {
    var intValue: Int64 { self ? 1 : 0 }
}

extension Int64 {
    var boolValue: Bool {
        return self != 0
    }
}
