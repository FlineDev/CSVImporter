//
//  CSVImporter.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 13.01.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//

import Foundation
import HandySwift

/// An enum to represent the possible line endings of CSV files.
public enum LineEnding: String {
    case nl = "\n"
    case cr = "\r"
    case crlf = "\r\n"
    case unknown = ""
}

private let chunkSize = 4096

/// Importer for CSV files that maps your lines to a specified data structure.
public class CSVImporter<T> {
    // MARK: - Stored Instance Properties

    let csvFile: TextFile
    let delimiter: String
    var lineEnding: LineEnding
    let encoding: String.Encoding

    var lastProgressReport: Date?

    var progressClosure: ((_ importedDataLinesCount: Int) -> Void)?
    var finishClosure: ((_ importedRecords: [T]) -> Void)?
    var failClosure: (() -> Void)?


    // MARK: - Computed Instance Properties

    var shouldReportProgress: Bool {
        return self.progressClosure != nil && (self.lastProgressReport == nil || Date().timeIntervalSince(self.lastProgressReport!) > 0.1)
    }


    // MARK: - Initializers

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// - Parameters:
    ///   - path: The path to the CSV file to import.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    ///   - lineEnding: The lineEnding of the file. If not specified will be determined automatically.
    public init(path: String, delimiter: String = ",", lineEnding: LineEnding = .unknown, encoding: String.Encoding = .utf8) {
        self.csvFile = TextFile(path: path, encoding: encoding)
        self.delimiter = delimiter
        self.lineEnding = lineEnding
        self.encoding = encoding

        delimiterQuoteDelimiter = "\(delimiter)\"\"\(delimiter)"
        delimiterDelimiter = delimiter+delimiter
        quoteDelimiter = "\"\"\(delimiter)"
        delimiterQuote = "\(delimiter)\"\""
    }

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// - Parameters:
    ///   - url: File URL for the CSV file to import.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    public convenience init?(url: URL, delimiter: String = ",", lineEnding: LineEnding = .unknown, encoding: String.Encoding = .utf8) {
        guard url.isFileURL else { return nil }
        self.init(path: url.path, delimiter: delimiter, lineEnding: lineEnding, encoding: encoding)
    }

    // MARK: - Instance Methods

    /// Starts importing the records within the CSV file line by line.
    ///
    /// - Parameters:
    ///   - mapper: A closure to map the data received in a line to your data structure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func startImportingRecords(mapper closure: @escaping (_ recordValues: [String]) -> T) -> Self {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            var importedRecords: [T] = []

            let importedLinesWithSuccess = self.importLines { valuesInLine in
                let newRecord = closure(valuesInLine)
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
    public func startImportingRecords(structure structureClosure: @escaping (_ headerValues: [String]) -> Void,
                                      recordMapper closure: @escaping (_ recordValues: [String: String]) -> T) -> Self {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            var recordStructure: [String]?
            var importedRecords: [T] = []

            let importedLinesWithSuccess = self.importLines { valuesInLine in

                if recordStructure == nil {
                    recordStructure = valuesInLine
                    structureClosure(valuesInLine)
                } else {
                    if let structuredValuesInLine = [String: String](keys: recordStructure!, values: valuesInLine) {
                        let newRecord = closure(structuredValuesInLine)
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
    func importLines(_ closure: (_ valuesInLine: [String]) -> Void) -> Bool {
        if lineEnding == .unknown {
            lineEnding = lineEndingForFile()
        }
        guard let csvStreamReader = self.csvFile.streamReader(lineEnding: lineEnding, chunkSize: chunkSize) else { return false }

        for line in csvStreamReader {
            autoreleasepool {
                let valuesInLine = readValuesInLine(line)
                closure(valuesInLine)
            }
        }

        return true
    }

    /// Determines the line ending for the CSV file
    ///
    /// - Returns: the lineEnding for the CSV file or default of NL.
    fileprivate func lineEndingForFile() -> LineEnding {
        var lineEnding: LineEnding = .nl
        if let fileHandle = self.csvFile.handleForReading {
            if let data = (fileHandle.readData(ofLength: chunkSize) as NSData).mutableCopy() as? NSMutableData {
                if let contents = NSString(bytesNoCopy: data.mutableBytes, length: data.length, encoding: encoding.rawValue, freeWhenDone: false) {
                    if contents.contains(LineEnding.crlf.rawValue) {
                        lineEnding = .crlf
                    } else if contents.contains(LineEnding.nl.rawValue) {
                        lineEnding = .nl
                    } else if contents.contains(LineEnding.cr.rawValue) {
                        lineEnding = .cr
                    }
                }
            }
        }
        return lineEnding
    }

    // Various private constants used for reading lines
    fileprivate let startPartRegex = try! NSRegularExpression(pattern: "\\A\"[^\"]*\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    fileprivate let middlePartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    fileprivate let endPartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\"\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    fileprivate let substitute = "\u{001a}"
    fileprivate let delimiterQuoteDelimiter: String
    fileprivate let delimiterDelimiter: String
    fileprivate let quoteDelimiter: String
    fileprivate let delimiterQuote: String

    /// Reads the line and returns the fields found. Handles double quotes according to RFC 4180.
    ///
    /// - Parameters:
    ///   - line: The line to read values from.
    /// - Returns: An array of values found in line.
    func readValuesInLine(_ line: String) -> [String] {
        var correctedLine = line.replacingOccurrences(of: delimiterQuoteDelimiter, with: delimiterDelimiter)

        if correctedLine.hasPrefix(quoteDelimiter) {
            correctedLine = correctedLine.substring(from: correctedLine.characters.index(correctedLine.startIndex, offsetBy: 2))
        }
        if correctedLine.hasSuffix(delimiterQuote) {
            correctedLine = correctedLine.substring(to: correctedLine.characters.index(correctedLine.startIndex, offsetBy: correctedLine.utf16.count - 2))
        }

        correctedLine = correctedLine.replacingOccurrences(of: "\"\"", with: substitute)
        var components = correctedLine.components(separatedBy: delimiter)

        var index = 0
        while index < components.count {
            let element = components[index]

            if index < components.count-1 && startPartRegex.firstMatch(in: element, options: .anchored, range: element.fullRange) != nil {
                var elementsToMerge = [element]

                while middlePartRegex.firstMatch(in: components[index+1], options: .anchored, range: components[index+1].fullRange) != nil {
                    elementsToMerge.append(components[index+1])
                    components.remove(at: index+1)
                }

                if endPartRegex.firstMatch(in: components[index+1], options: .anchored, range: components[index+1].fullRange) != nil {
                    elementsToMerge.append(components[index+1])
                    components.remove(at: index+1)
                    components[index] = elementsToMerge.joined(separator: delimiter)
                } else {
                    print("Invalid CSV format in line, opening \" must be closed – line: \(line).")
                }
            }

            index += 1
        }

        components = components.map { $0.replacingOccurrences(of: "\"", with: "") }
        components = components.map { $0.replacingOccurrences(of: substitute, with: "\"") }

        return components
    }

    /// Defines callback to be called in case reading the CSV file fails.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on failure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func onFail(_ closure: @escaping () -> Void) -> Self {
        self.failClosure = closure
        return self
    }

    /// Defines callback to be called from time to time.
    /// Use this to indicate progress to a user when importing bigger files.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on progress. Takes the current count of imported lines as argument.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func onProgress(_ closure: @escaping (_ importedDataLinesCount: Int) -> Void) -> Self {
        self.progressClosure = closure
        return self
    }

    /// Defines callback to be called when the import finishes.
    ///
    /// - Parameters:
    ///   - closure: The closure to be called on finish. Takes the array of all imported records mapped to as its argument.
    public func onFinish(_ closure: @escaping (_ importedRecords: [T]) -> Void) {
        self.finishClosure = closure
    }


    // MARK: - Helper Methods

    func reportFail() {
        if let failClosure = self.failClosure {
            DispatchQueue.main.async {
                failClosure()
            }
        }
    }

    func reportProgressIfNeeded(_ importedRecords: [T]) {
        if self.shouldReportProgress {
            self.lastProgressReport = Date()

            if let progressClosure = self.progressClosure {
                DispatchQueue.main.async {
                    progressClosure(importedRecords.count)
                }
            }
        }
    }

    func reportFinish(_ importedRecords: [T]) {
        if let finishClosure = self.finishClosure {
            DispatchQueue.main.async {
                finishClosure(importedRecords)
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
