// Wayfinder

import Foundation

class Migrator {
    
    let sqlUp: String
    let sqlDown: String
    
    private init(sqlUp: String, sqlDown: String) {
        self.sqlUp = sqlUp
        self.sqlDown = sqlDown
    }
    
    static func open(url: URL) throws -> Migrator {
        var sql: [String]
        let content = try String(contentsOf: url, encoding: String.Encoding.utf8)
        sql = content.components(separatedBy: "\n")
        
        var goingUp: Bool? = nil
        var sqlUp: String = ""
        var sqlDown: String = ""
        
        for sqlLine in sql {
            if sqlLine.uppercased().starts(with: "-- UP") {
                goingUp = true
            } else if sqlLine.uppercased().starts(with: "-- DOWN") {
                goingUp = false
            }
            
            if let goingUp = goingUp {
                if goingUp {
                    sqlUp.append(sqlLine + "\n")
                } else {
                    sqlDown.append(sqlLine + "\n")
                }
            }
        }
        
        return Migrator(sqlUp: sqlUp, sqlDown: sqlDown)
    }
}
