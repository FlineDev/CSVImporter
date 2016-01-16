import Foundation
import CSVImporter
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

if let path = NSBundle.mainBundle().pathForResource("Teams", ofType: "csv") {
    
    path
    let importer = CSVImporter<[String]>(path: path)
    
    importer.startImportingRecords{ $0 }.onFail {
            
        print("Did fail")
            
    }.onProgress { importedDataLinesCount in
            
        print("Progress: \(importedDataLinesCount)")
            
    }.onFinish { importedRecords in
            
        print("Did finish import, first array: \(importedRecords.first)")
        importedRecords
        XCPlaygroundPage.currentPage.finishExecution()
        
    }
    
}
