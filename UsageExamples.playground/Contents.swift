import Foundation
import CSVImporter

class Team {
    let yearID: Int, lgID: String, teamID: String
    
    init(yearID: Int, lgID: String, teamID: String) {
        self.yearID = yearID
        self.lgID = lgID
        self.teamID = teamID
    }
}

if let teamsFilePath = NSBundle.mainBundle().pathForResource("Teams", ofType: "csv") {
    
    let teamsImporter = CSVImporter<Team>(filePath: teamsFilePath)
    
    teamsImporter.startImportingWithMapper { readValuesInLine -> Team in
        
        return Team(yearID: Int(readValuesInLine[0])!, lgID: readValuesInLine[1], teamID: readValuesInLine[2])
        
    }.onProgress { importedDataLinesCount, totalNumberOfDataLines in
        
        print("Current progress: \(importedDataLinesCount / totalNumberOfDataLines * 100)%")
        
    }.onFinish { importedRecords in
        
        // do something with imported records
        
    }
}

