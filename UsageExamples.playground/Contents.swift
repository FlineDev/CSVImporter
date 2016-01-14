import Foundation
import CSVImporter

if let path = NSBundle.mainBundle().pathForResource("Teams", ofType: "csv") {
    let importer = CSVImporter<[String]>(path: path)
    
    importer.startImportingWithMapper { readValuesInLine -> [String] in
        
        return readValuesInLine
        
    }.onFail {
        
        print("Did fail")
        
    }.onProgress { importedDataLinesCount in
        
        print("Progress: \(importedDataLinesCount)")
        
    }.onFinish { importedRecords in
        
        print("Did finish import, first array: \(importedRecords.first)")
        
    }
}
