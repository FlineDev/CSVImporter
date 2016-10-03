import Foundation
import CSVImporter
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: Get the path to an example CSV file (see Resources folder of this Playground).
let path = Bundle.main.path(forResource: "Teams", ofType: "csv")!

//: ## CSVImporter
//: The CSVImporter class is the class which includes all the import logic.

//: ### init<T>(path:)
//: First create an instance of CSVImporter. Let's do this with the default type `[String]` like this:

let defaultImporter = CSVImporter<[String]>(path: path)

//: ### Basic import: .startImportingRecords & .onFinish
//: For a basic line-by-line import of your file start the import and use the `.onFinish` callback. The import is done asynchronously but all callbacks (like `.onFinish`) are called on the main thread.

defaultImporter.startImportingRecords{ $0 }.onFinish { importedRecords in
    
    type(of: importedRecords)
    importedRecords.count   // number of all records
    importedRecords[100]    // this is a single record
    importedRecords         // array with all records (in this case an array of arrays)
    
}

//: ### .onFail
//: In case your path was wrong the chainable `.onFail` callback will be called instead of the `.onFinish`.

let wrongPathImporter = CSVImporter<[String]>(path: "a/wrong/path")
wrongPathImporter.startImportingRecords{ $0 }.onFail {
    
    ".onFail called because the path is wrong"
    
}.onFinish { importedRecords in
    
    ".onFinish is never called here because the path is wrong"
    
}

//: ### .onProgress
//: If you want to show progress to your users you can use the `.onProgress` callback. It will be called multiple times a second with the current number of lines already processed.

defaultImporter.startImportingRecords{ $0 }.onProgress { importedDataLinesCount in
    
    importedDataLinesCount
    "Progress Update in main thread: \(importedDataLinesCount) lines were imported"
    
}

//: ### .startImportingRecords(structure:)
//: Some CSV files offer some structural information about the data on the first line (the header line). You can also tell CSVImporter to use this first line to return a dictionary where the structure information are used as keys. The default data type for structural imports therefore is a String dictionary (`[String: String]`).

let structureImporter = CSVImporter<[String: String]>(path: path)
structureImporter.startImportingRecords(structure: { headerValues in
    
    headerValues // the structural information from the first line as a [String]

}){ $0 }.onFinish { importedRecords in
    
    type(of: importedRecords)
    importedRecords.count           // the number of all imported records
    importedRecords[99]             // this is a single record
    
}

//: ### .startImportingRecords(mapper:)
//: You don't need to use the default types `[String]` for the default importer. You can use your own type by proving your own mapper instead of `{ $0 }` from the examples above. The mapper gets a `[String]` and needs to return your own type.

// Let's define our own class:
class Team {
    let year: String, league: String
    init(year: String, league: String) {
        self.year = year
        self.league = league
    }
}

// Now create an importer for our own type and start importing:
let teamsDefaultImporter = CSVImporter<Team>(path: path)
teamsDefaultImporter.startImportingRecords { recordValues -> Team in
    
    return Team(year: recordValues[0], league: recordValues[1])
    
}.onFinish { importedRecords in
    
    type(of: importedRecords)     // the type is now [Team]
    importedRecords.count           // number of all imported records

    let aTeam = importedRecords[100]
    aTeam.year
    aTeam.league
    
}

//: ### .startImportingRecords(structure:recordMapper:)
//: You can also use a record mapper and use structured data together. In this case the mapper gets a `[String: String]` and needs to return with your own type again.

let teamsStructuredImporter = CSVImporter<Team>(path: path)
teamsStructuredImporter.startImportingRecords(structure: { headerValues in
    
    headerValues // the structure form the first line of the CSV file
    
}) { recordValues -> Team in
    
    return Team(year: recordValues["yearID"]!, league: recordValues["lgID"]!)
    
}.onFinish { (importedRecords) -> Void in
    
    type(of: importedRecords)     // the type is now [Team]
    importedRecords.count           // number of all imported records
    
    let aTeam = importedRecords[99]
    aTeam.year
    aTeam.league
    
}

//: Note that the structural importer is slower than the default importer.

//: You can also build an importer with a file URL
//: Get the file URL to an example CSV file (see Resources folder of this Playground).
let fileURL = Bundle.main.url(forResource: "Teams.csv", withExtension: nil)!

//: ## CSVImporter
//: The CSVImporter class is the class that includes all the import logic.

//: ### init<T>(path:)
//: First create an instance of CSVImporter. Let's do this with the default type `[String]` like this:

let fileURLImporter = CSVImporter<[String]>(url: fileURL)

//: ### Basic import: .startImportingRecords & .onFinish
//: For a basic line-by-line import of your file start the import and use the `.onFinish` callback. The import is done asynchronously but all callbacks (like `.onFinish`) are called on the main thread.

fileURLImporter?.startImportingRecords{ $0 }.onFinish { importedRecords in

    type(of: importedRecords)
    importedRecords.count   // number of all records
    importedRecords[100]    // this is a single record
    importedRecords         // array with all records (in this case an array of arrays)

}

