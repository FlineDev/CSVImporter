
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

        it("calls onFail block with wrong path") {
            let invalidPath = "invalid/path"

            var didFail = false
            let importer = CSVImporter<[String]>(path: invalidPath)

            importer.startImportingRecords { $0 }.onFail {
                didFail = true
                print("Did fail")
            }.onProgress { importedDataLinesCount in
                print("Progress: \(importedDataLinesCount)")
            }.onFinish { importedRecords in
                print("Did finish import, first array: \(importedRecords.first)")
            }

            expect(didFail).toEventually(beTrue())
        }

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

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
        }

        it("imports data from CSV file special characters") {
            let path = NSBundle(forClass: CSVImporterSpec.classForCoder()).pathForResource("CommaSemicolonQuotes", ofType: "csv")
            var recordValues: [[String]]?

            if let path = path {
                let importer = CSVImporter<[String]>(path: path, delimiter: ";")

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
            expect(recordValues?.first).toEventuallyNot(beNil())
            expect(recordValues!.first!).toEventually(equal([
                "",
                "Text, with \"comma\"; and 'semicolon'.",
                "",
                "Another text with \"comma\"; and 'semicolon'!",
                "Text without special chars.",
                ""
            ]))
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

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
        }

        it("zz") { }
    }
}
