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
            
            var recordValues: [[String]]?
            
            if let path = path {
                let importer = CSVImporter<[String]>(path: path)
                
                importer.startImportingRecords { recordValues -> [String] in
                    
                    return recordValues
                    
                }.onFail {
                        
                        print("Did fail")
                        
                }.onProgress { importedDataLinesCount in
                        
                        print("Progress: \(importedDataLinesCount)")
                        
                }.onFinish { importedRecords in
                        
                        print("Did finish import, first array: \(importedRecords.first)")
                        recordValues = importedRecords
                        
                }
            }

            expect(recordValues).toEventuallyNot(beNil())
            
        }
        
        it("imports data from CSV file with headers") {
            
            let path = NSBundle(forClass: CSVImporterSpec.classForCoder()).pathForResource("Teams", ofType: "csv")
            
            var recordValues: [[String: String]]?
            
            if let path = path {
                let importer = CSVImporter<[String: String]>(path: path)
                
                importer.startImportingRecords(structure: { (headerValues) -> Void in
                    
                    print(headerValues)
                    
                }, recordMapper: { (recordValues) -> [String : String] in
                    
                    return recordValues
                    
                }).onFail {
                        
                        print("Did fail")
                        
                }.onProgress { importedDataLinesCount in
                        
                        print("Progress: \(importedDataLinesCount)")
                        
                }.onFinish { importedRecords in
                        
                        print("Did finish import, first array: \(importedRecords.first)")
                        recordValues = importedRecords
                        
                }
            }
            
            expect(recordValues).toEventuallyNot(beNil(), timeout: 3)
            
            
        }
        
        
        
    }
    
}
