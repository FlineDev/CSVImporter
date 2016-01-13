import Foundation
import CSVImporter

if let teamsFilePath = NSBundle.mainBundle().pathForResource("Teams", ofType: "csv") {
    
    let teamsImporter = CSVImporter(filePath: teamsFilePath)
    
    
}

