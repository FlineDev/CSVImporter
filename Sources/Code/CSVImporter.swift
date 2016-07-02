//
//  CSVImporter.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation
import FileKit
import HandySwift

/// Importer for CSV files that maps your lines to a specified data structure.
public class CSVImporter<T> {

    // MARK: - Stored Instance Properties

    let csvFile: TextFile
    let delimiter: String

    var lastProgressReport: NSDate?

    var progressClosure: ((importedDataLinesCount: Int) -> Void)?
    var finishClosure: ((importedRecords: [T]) -> Void)?
    var failClosure: (() -> Void)?


    // MARK: - Computes Instance Properties

    var shouldReportProgress: Bool {
        get {
            return self.progressClosure != nil &&
                (self.lastProgressReport == nil || NSDate().timeIntervalSinceDate(self.lastProgressReport!) > 0.1)
        }
    }


    // MARK: - Initializers

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// - Parameters:
    ///   - path: The path to the CSV file to import.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    public init(path: String, delimiter: String = ",") {
        self.csvFile = TextFile(path: Path(path))
        self.delimiter = delimiter
    }


    // MARK: - Instance Methods

    /// Starts importing the records within the CSV file line by line.
    ///
    /// - Parameters:
    ///   - mapper: A closure to map the data received in a line to your data structure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func startImportingRecords(mapper closure: (recordValues: [String]) -> T) -> Self {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            var importedRecords: [T] = []

            let importedLinesWithSuccess = self.importLines { valuesInLine in
                let newRecord = closure(recordValues: valuesInLine)
                importedRecords.append(newRecord)

                self.reportProgressIfNeeded(importedRecords)
            }

            if importedLinesWithSuccess {
                self.reportFinish(importedRecords)
            } else {
                self.reportFail()
            }
        }

        return self
    }

    /// Starts importing the records within the CSV file line by line interpreting the first line as the data structure.
    ///
    /// - Parameters:
    ///   - structure: A closure for doing something with the found structure within the first line of the CSV file.
    ///   - recordMapper: A closure to map the dictionary data interpreted from a line to your data structure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func startImportingRecords(structure structureClosure: (headerValues: [String]) -> Void, recordMapper closure: (recordValues: [String: String]) -> T) -> Self {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            var recordStructure: [String]?
            var importedRecords: [T] = []

            let importedLinesWithSuccess = self.importLines { valuesInLine in

                if recordStructure == nil {
                    recordStructure = valuesInLine
                    structureClosure(headerValues: valuesInLine)
                } else {
                    if let structuredValuesInLine = [String: String](keys: recordStructure!, values: valuesInLine) {
                        let newRecord = closure(recordValues: structuredValuesInLine)
                        importedRecords.append(newRecord)

                        self.reportProgressIfNeeded(importedRecords)
                    } else {
                        print("Warning: Couldn't structurize line.")
                    }
                }
            }

            if importedLinesWithSuccess {
                self.reportFinish(importedRecords)
            } else {
                self.reportFail()
            }
        }

        return self
    }

    /// Imports all lines one by one and
    ///
    /// - Parameters:
    ///   - valuesInLine: The values found within a line.
    /// - Returns: `true` on finish or `false` if can't read file.
    func importLines(closure: (valuesInLine: [String]) -> Void) -> Bool {
        if let csvStreamReader = self.csvFile.streamReader() {
            for line in csvStreamReader {
                let valuesInLine = readValuesInLine(line)
                closure(valuesInLine: valuesInLine)
            }

            return true
        } else {
            return false
        }
    }

    /// Reads the line and returns the fields found. Handles double quotes according to RFC 4180.
    ///
    /// - Parameters:
    ///   - line: The line to read values from.
    /// - Returns: An array of values found in line.
    func readValuesInLine(line: String) -> [String] {
        var correctedLine = line.stringByReplacingOccurrencesOfString("\(delimiter)\"\"\(delimiter)", withString: delimiter+delimiter)
        correctedLine = correctedLine.stringByReplacingOccurrencesOfString("\r\n", withString: "\n")

        if correctedLine.hasPrefix("\"\"\(delimiter)") {
            correctedLine = correctedLine.substringFromIndex(correctedLine.startIndex.advancedBy(2))
        }
        if correctedLine.hasSuffix("\(delimiter)\"\"") || correctedLine.hasSuffix("\(delimiter)\"\"\n") {
            correctedLine = correctedLine.substringToIndex(correctedLine.startIndex.advancedBy(correctedLine.utf16.count - 2))
        }

        let substitute = "\u{001a}"
        correctedLine = correctedLine.stringByReplacingOccurrencesOfString("\"\"", withString: substitute)
        var components = correctedLine.componentsSeparatedByString(delimiter)

        var index = 0
        while index < components.count {
            let element = components[index]

            let startPartRegex = try! NSRegularExpression(pattern: "\\A\"[^\"]*\\z", options: .CaseInsensitive) // swiftlint:disable:this force_try

            if index < components.count-1 && startPartRegex.firstMatchInString(element, options: .Anchored, range: element.fullRange) != nil {
                var elementsToMerge = [element]

                let middlePartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\\z", options: .CaseInsensitive) // swiftlint:disable:this force_try
                let endPartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\"\\z", options: .CaseInsensitive) // swiftlint:disable:this force_try

                while middlePartRegex.firstMatchInString(components[index+1], options: .Anchored, range: components[index+1].fullRange) != nil {
                    elementsToMerge.append(components[index+1])
                    components.removeAtIndex(index+1)
                }

                if endPartRegex.firstMatchInString(components[index+1], options: .Anchored, range: components[index+1].fullRange) != nil {
                    elementsToMerge.append(components[index+1])
                    components.removeAtIndex(index+1)
                    components[index] = elementsToMerge.joinWithSeparator(delimiter)
                } else {
                    print("Invalid CSV format in line, opening \" must be closed – line: \(line).")
                }
            }

            index += 1
        }

        components = components.map { $0.stringByReplacingOccurrencesOfString("\"", withString: "") }
        components = components.map { $0.stringByReplacingOccurrencesOfString(substitute, withString: "\"") }

        return components
    }

    /// Defines callback to be called in case reading the CSV file fails.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on failure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func onFail(closure: () -> Void) -> Self {
        self.failClosure = closure
        return self
    }

    /// Defines callback to be called from time to time.
    /// Use this to indicate progress to a user when importing bigger files.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on progress. Takes the current count of imported lines as argument.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func onProgress(closure: (importedDataLinesCount: Int) -> Void) -> Self {
        self.progressClosure = closure
        return self
    }

    /// Defines callback to be called when the import finishes.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on finish. Takes the array of all imported records mapped to as its argument.
    public func onFinish(closure: (importedRecords: [T]) -> Void) {
        self.finishClosure = closure
    }


    // MARK: - Helper Methods

    func reportFail() {
        if let failClosure = self.failClosure {
            dispatch_async(dispatch_get_main_queue()) {
                failClosure()
            }
        }
    }

    func reportProgressIfNeeded(importedRecords: [T]) {
        if self.shouldReportProgress {
            self.lastProgressReport = NSDate()

            if let progressClosure = self.progressClosure {
                dispatch_async(dispatch_get_main_queue()) {
                    progressClosure(importedDataLinesCount: importedRecords.count)
                }
            }
        }

    }

    func reportFinish(importedRecords: [T]) {
        if let finishClosure = self.finishClosure {
            dispatch_async(dispatch_get_main_queue()) {
                finishClosure(importedRecords: importedRecords)
            }
        }
    }


}


// MARK: - Helpers

extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: self.utf16.count)
    }
}