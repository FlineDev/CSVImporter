//
//  CSVImporterSpec.swift
//  CSVImporterSpec
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import XCTest

import Quick
import Nimble

@testable import CSVImporter

class CSVImporterSpec: QuickSpec {
    
    override func spec() {
        
        it("imports data from CSV file without headers") {
            
            let path = NSBundle(forClass: CSVImporterSpec.classForCoder()).pathForResource("Teams", ofType: "csv")
            
            var readValues: [[String]]?
            
            if let path = path {
                let importer = CSVImporter<[String]>(path: path)
                
                importer.startImportingWithMapper { readValuesInLine -> [String] in
                    
                    return readValuesInLine
                    
                    }.onFail {
                        
                        print("Did fail")
                        
                    }.onProgress { importedDataLinesCount in
                        
                        print("Progress: \(importedDataLinesCount)")
                        
                    }.onFinish { importedRecords in
                        
                        print("Did finish import, first array: \(importedRecords.first)")
                        readValues = importedRecords
                        
                }
            }

            expect(readValues).toEventuallyNot(beNil())
            
        }
        
    }
    
}
