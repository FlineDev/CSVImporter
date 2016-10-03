
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
            let path = Bundle(for: CSVImporterSpec.classForCoder()).path(forResource: "Teams", ofType: "csv")
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
            let path = Bundle(for: CSVImporterSpec.classForCoder()).path(forResource: "CommaSemicolonQuotes", ofType: "csv")
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
            let path = Bundle(for: CSVImporterSpec.classForCoder()).path(forResource: "Teams", ofType: "csv")
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
            expect(recordValues!.first!).toEventually(equal(self.validTeamsFirstRecord()))
        }

        it("imports data from CSV file with headers Specifying lineEnding") {
            let path = self.pathForResourceFile("Teams.csv")
            var recordValues: [[String: String]]?

            if let path = path {
                let importer = CSVImporter<[String: String]>(path: path, lineEnding: .CRLF)

                importer.startImportingRecords(structure: { (headerValues) -> Void in
                    print(headerValues)
                }, recordMapper: { (recordValues) -> [String : String] in
                        return recordValues
                }).onFail {
                    print("Did fail")
                }.onFinish { importedRecords in
                    print("Did finish import, first array: \(importedRecords.first)")
                    recordValues = importedRecords
                }
            }

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
            expect(recordValues!.first!).toEventually(equal(self.validTeamsFirstRecord()))
        }

        it("imports data from CSV file with headers Specifying lineEnding NL") {
            let path = self.convertTeamsLineEndingTo(.NL)
            var recordValues: [[String: String]]?

            if let path = path {
                let importer = CSVImporter<[String: String]>(path: path, lineEnding: .NL)

                importer.startImportingRecords(structure: { (headerValues) -> Void in
                    print(headerValues)
                }, recordMapper: { (recordValues) -> [String : String] in
                        return recordValues
                }).onFail {
                    print("Did fail")
                }.onFinish { importedRecords in
                    print("Did finish import, first array: \(importedRecords.first)")
                    recordValues = importedRecords
                }
            }

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
            expect(recordValues!.first!).toEventually(equal(self.validTeamsFirstRecord()))

            self.deleteFileSilently(path)
        }

        it("imports data from CSV file with headers with lineEnding CR Sniffs lineEnding") {
            let path = self.convertTeamsLineEndingTo(.CR)
            var recordValues: [[String: String]]?

            if let path = path {
                let importer = CSVImporter<[String: String]>(path: path) // don't specify lineEnding

                importer.startImportingRecords(structure: { (headerValues) -> Void in
                    print(headerValues)
                }, recordMapper: { (recordValues) -> [String : String] in
                    return recordValues
                }).onFail {
                    print("Did fail")
                }.onFinish { importedRecords in
                    print("Did finish import, first array: \(importedRecords.first)")
                    recordValues = importedRecords
                }
            }

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
            expect(recordValues!.first!).toEventually(equal(self.validTeamsFirstRecord()))

            self.deleteFileSilently(path)
        }

        it("imports data from CSV file with headers Specifying Wrong lineEnding Fails") {
            let path = self.pathForResourceFile("Teams.csv")
            var recordValues: [[String: String]]?

            if let path = path {
                do {
                    let string = try String(contentsOfFile: path)
                    expect(string.contains(LineEnding.CRLF.rawValue)).to(beTrue())
                } catch { }

                let importer = CSVImporter<[String: String]>(path: path, lineEnding: .NL)    // wrong

                importer.startImportingRecords(structure: { (headerValues) -> Void in
                    print(headerValues)
                }, recordMapper: { (recordValues) -> [String : String] in
                    return recordValues
                }).onFail {
                    print("Did fail")
                }.onFinish { importedRecords in
                    print("Did finish import, first array: \(importedRecords.first)")
                    recordValues = importedRecords
                }
            }
            
            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
            expect(recordValues!.first!).toEventuallyNot(equal(self.validTeamsFirstRecord()))
        }

        it("imports data from CSV file with headers using File URL") {
            let url = Bundle(for: CSVImporterSpec.classForCoder()).url(forResource: "Teams.csv", withExtension: nil)
            var recordValues: [[String: String]]?

            if let url = url {
                if let importer = CSVImporter<[String: String]>(url: url) {

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
            }

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
            expect(recordValues!.first!).toEventually(equal(self.validTeamsFirstRecord()))
        }

        it("imports data from CSV file with headers using Web URL Fails") {
            let url = URL(string: "https://www.apple.com")
            var recordValues: [[String: String]]?
            var didFail = false

            if let url = url {
                if let importer = CSVImporter<[String: String]>(url: url) {

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
                } else {
                    didFail = true
                }
            }
            
            expect(recordValues).toEventually(beNil(), timeout: 10)
            expect(didFail).toEventually(beTrue())
        }

        it("imports data from CSV file with headers using File URL") {
            let url = Bundle(for: CSVImporterSpec.classForCoder()).url(forResource: "Teams.csv", withExtension: nil)
            var recordValues: [[String: String]]?

            if let url = url {
                if let importer = CSVImporter<[String: String]>(url: url) {

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
            }

            expect(recordValues).toEventuallyNot(beNil(), timeout: 10)
        }

        it("imports data from CSV file with headers using Web URL Fails") {
            let url = URL(string: "https://www.apple.com")
            var recordValues: [[String: String]]?
            var didFail = false

            if let url = url {
                if let importer = CSVImporter<[String: String]>(url: url) {

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
                } else {
                    didFail = true
                }
            }

            expect(recordValues).toEventually(beNil(), timeout: 10)
            expect(didFail).toEventually(beTrue())
        }

        it("zz") { }
    }

    func validTeamsFirstRecord() -> [String:String] {
        return ["H": "426", "SOA": "23", "SO": "19", "WCWin": "", "AB": "1372", "BPF": "103", "IPouts": "828", "PPF": "98", "3B": "37", "BB": "60", "HBP": "", "lgID": "NA", "ER": "109", "CG": "22", "name": "Boston Red Stockings", "yearID": "1871", "divID": "", "teamIDretro": "BS1", "FP": "0.83", "R": "401", "G": "31", "BBA": "42", "HA": "367", "RA": "303", "park": "South End Grounds I", "DivWin": "", "WSWin": "", "HR": "3", "E": "225", "ERA": "3.55", "franchID": "BNA", "DP": "", "L": "10", "LgWin": "N", "W": "20", "SV": "3", "SHO": "1", "Rank": "3", "Ghome": "", "teamID": "BS1", "teamIDlahman45": "BS1", "HRA": "2", "SF": "", "attendance": "", "CS": "", "teamIDBR": "BOS", "SB": "73", "2B": "70"]
    }

    func convertTeamsLineEndingTo(_ lineEnding:LineEnding) -> String? {
        if let path = pathForResourceFile("Teams.csv") {
            do {
                let string = try String(contentsOfFile: path)
                expect(string.contains(LineEnding.CRLF.rawValue)).to(beTrue())
                let crString = string.replacingOccurrences(of: LineEnding.CRLF.rawValue, with: lineEnding.rawValue)
                let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent("TeamsNewLineEnding.csv")
                try crString.write(toFile: tempPath, atomically: false, encoding: String.Encoding.utf8)
                return tempPath
            } catch {
                // TODO: Some kind of error handling
            }
        }

        return nil
    }

    func pathForResourceFile(_ name:String) -> String? {
        return Bundle(for: CSVImporterSpec.classForCoder()).path(forResource: name, ofType: nil)
    }

    func deleteFileSilently(_ path:String?) {
        guard let path = path else { return }
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch { }
    }

}
