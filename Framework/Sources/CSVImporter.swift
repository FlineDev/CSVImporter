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
    case newLine = "\n"
    case carriageReturn = "\r"
    case carriageReturnLineFeed = "\r\n"
    case unknown = ""
}

/// Importer for CSV files that maps your lines to a specified data structure.
public class CSVImporter<T> {
    // MARK: - Stored Instance Properties
    let source: Source
    let delimiter: String

    var lastProgressReport: Date?

    var progressClosure: ((_ importedDataLinesCount: Int) -> Void)?
    var finishClosure: ((_ importedRecords: [T]) -> Void)?
    var failClosure: (() -> Void)?

    let workQosClass: DispatchQoS.QoSClass
    let callbacksQosClass: DispatchQoS.QoSClass?

    // MARK: - Computed Instance Properties
    var shouldReportProgress: Bool {
        return self.progressClosure != nil && (self.lastProgressReport == nil || Date().timeIntervalSince(self.lastProgressReport!) > 0.1)
    }

    var workDispatchQueue: DispatchQueue {
        return DispatchQueue.global(qos: workQosClass)
    }

    var callbacksDispatchQueue: DispatchQueue {
        guard let callbacksQosClass = callbacksQosClass else { return DispatchQueue.main }
        return DispatchQueue.global(qos: callbacksQosClass)
    }

    // MARK: - Initializers
    /// Internal initializer to prevent duplicate code.
    private init(source: Source, delimiter: String, workQosClass: DispatchQoS.QoSClass, callbacksQosClass: DispatchQoS.QoSClass?) {
        self.source = source
        self.delimiter = delimiter
        self.workQosClass = workQosClass
        self.callbacksQosClass = callbacksQosClass

        delimiterQuoteDelimiter = "\(delimiter)\"\"\(delimiter)"
        delimiterDelimiter = delimiter + delimiter
        quoteDelimiter = "\"\"\(delimiter)"
        delimiterQuote = "\(delimiter)\"\""
    }

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// - Parameters:
    ///   - path: The path to the CSV file to import.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    ///   - lineEnding: The lineEnding used in the file. If not specified will be determined automatically.
    ///   - encoding: The encoding the file is read with. Defaults to `.utf8`.
    ///   - workQosClass: The QOS class of the background queue to run the heavy work in. Defaults to `.utility`.
    ///   - callbacksQosClass: The QOS class of the background queue to run the callbacks in or `nil` for the main queue. Defaults to `nil`.
    public convenience init(path: String, delimiter: String = ",", lineEnding: LineEnding = .unknown, encoding: String.Encoding = .utf8,
                            workQosClass: DispatchQoS.QoSClass = .utility, callbacksQosClass: DispatchQoS.QoSClass? = nil) {
        let textFile = TextFile(path: path, encoding: encoding)
        let fileSource = FileSource(textFile: textFile, encoding: encoding, lineEnding: lineEnding)
        self.init(source: fileSource, delimiter: delimiter, workQosClass: workQosClass, callbacksQosClass: callbacksQosClass)
    }

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// - Parameters:
    ///   - url: File URL for the CSV file to import.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    ///   - lineEnding: The lineEnding used in the file. If not specified will be determined automatically.
    ///   - encoding: The encoding the file is read with. Defaults to `.utf8`.
    ///   - workQosClass: The QOS class of the background queue to run the heavy work in. Defaults to `.utility`.
    ///   - callbacksQosClass: The QOS class of the background queue to run the callbacks in or `nil` for the main queue. Defaults to `nil`.
    public convenience init?(url: URL, delimiter: String = ",", lineEnding: LineEnding = .unknown, encoding: String.Encoding = .utf8,
                             workQosClass: DispatchQoS.QoSClass = .utility, callbacksQosClass: DispatchQoS.QoSClass? = nil) {
        guard url.isFileURL else { return nil }
        self.init(path: url.path, delimiter: delimiter, lineEnding: lineEnding, encoding: encoding, workQosClass: workQosClass, callbacksQosClass: callbacksQosClass)
    }

    /// Creates a `CSVImporter` object with required configuration options.
    ///
    /// NOTE: This initializer doesn't save any memory as the given String is already loaded into memory.
    ///       Don't use this if you are working with a large file which you could refer to with a path also.
    ///
    /// - Parameters:
    ///   - contentString: The string which contains the content of a CSV file.
    ///   - delimiter: The delimiter used within the CSV file for separating fields. Defaults to ",".
    ///   - lineEnding: The lineEnding used in the file. If not specified will be determined automatically.
    ///   - workQosClass: The QOS class of the background queue to run the heavy work in. Defaults to `.utility`.
    ///   - callbacksQosClass: The QOS class of the background queue to run the callbacks in or `nil` for the main queue. Defaults to `nil`.
    public convenience init(contentString: String, delimiter: String = ",", lineEnding: LineEnding = .unknown,
                            workQosClass: DispatchQoS.QoSClass = .utility, callbacksQosClass: DispatchQoS.QoSClass? = nil) {
        let stringSource = StringSource(contentString: contentString, lineEnding: lineEnding)
        self.init(source: stringSource, delimiter: delimiter, workQosClass: workQosClass, callbacksQosClass: callbacksQosClass)
    }

    // MARK: - Instance Methods
    /// Starts importing the records within the CSV file line by line.
    ///
    /// - Parameters:
    ///   - mapper: A closure to map the data received in a line to your data structure.
    /// - Returns: `self` to enable consecutive method calls (e.g. `importer.startImportingRecords {...}.onProgress {...}`).
    public func startImportingRecords(mapper closure: @escaping (_ recordValues: [String]) -> T) -> Self {
        workDispatchQueue.async {
            var importedRecords = [T]()

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
        workDispatchQueue.async {
            var recordStructure: [String]?
            var importedRecords = [T]()

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

    /// Synchronously imports all records and provides the end result only.
    ///
    /// Use the `startImportingRecords` method for an asynchronous import with progress, fail and finish callbacks.
    ///
    /// - Parameters:
    ///   - mapper: A closure to map the data received in a line to your data structure.
    /// - Returns: The imported records array.
    public func importRecords(mapper closure: @escaping (_ recordValues: [String]) -> T) -> [T] {
        var importedRecords = [T]()

        _ = self.importLines { valuesInLine in
            let newRecord = closure(valuesInLine)
            importedRecords.append(newRecord)
        }

        return importedRecords
    }

    /// Synchronously imports all records and provides the end result only.
    ///
    /// Use the `startImportingRecords` method for an asynchronous import with progress, fail and finish callbacks.
    ///
    ///   - structure: A closure for doing something with the found structure within the first line of the CSV file.
    ///   - recordMapper: A closure to map the dictionary data interpreted from a line to your data structure.
    /// - Returns: The imported records array.
    public func importRecords(structure structureClosure: @escaping (_ headerValues: [String]) -> Void,
                              recordMapper closure: @escaping (_ recordValues: [String: String]) -> T) -> [T] {
        var recordStructure: [String]?
        var importedRecords = [T]()

        _ = self.importLines { valuesInLine in

            if recordStructure == nil {
                recordStructure = valuesInLine
                structureClosure(valuesInLine)
            } else {
                if let structuredValuesInLine = [String: String](keys: recordStructure!, values: valuesInLine) {
                    let newRecord = closure(structuredValuesInLine)
                    importedRecords.append(newRecord)
                } else {
                    print("CSVImporter – Warning: Couldn't structurize line.")
                }
            }
        }

        return importedRecords
    }

    /// Imports all lines one by one and
    ///
    /// - Parameters:
    ///   - valuesInLine: The values found within a line.
    /// - Returns: `true` on finish or `false` if can't read file.
    func importLines(_ closure: (_ valuesInLine: [String]) -> Void) -> Bool {
        var anyLine = false

        source.forEach { line in
            anyLine = true
            autoreleasepool {
                let valuesInLine = readValuesInLine(line)
                closure(valuesInLine)
            }
        }

        return anyLine
    }

    // Various private constants used for reading lines
    private let startPartRegex = try! NSRegularExpression(pattern: "\\A\"[^\"]*\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    private let middlePartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    private let endPartRegex = try! NSRegularExpression(pattern: "\\A[^\"]*\"\\z", options: .caseInsensitive) // swiftlint:disable:this force_try
    private let substitute = "\u{001a}"
    private let delimiterQuoteDelimiter: String
    private let delimiterDelimiter: String
    private let quoteDelimiter: String
    private let delimiterQuote: String

    /// Reads the line and returns the fields found. Handles double quotes according to RFC 4180.
    ///
    /// - Parameters:
    ///   - line: The line to read values from.
    /// - Returns: An array of values found in line.
    func readValuesInLine(_ line: String) -> [String] {
        var correctedLine = line.replacingOccurrences(of: delimiterQuoteDelimiter, with: delimiterDelimiter)

        if correctedLine.hasPrefix(quoteDelimiter) {
            correctedLine = String(correctedLine.suffix(from: correctedLine.index(correctedLine.startIndex, offsetBy: 2)))
        }

        if correctedLine.hasSuffix(delimiterQuote) {
            correctedLine = String(correctedLine.prefix(upTo: correctedLine.index(correctedLine.startIndex, offsetBy: correctedLine.utf16.count - 2)))
        }

        correctedLine = correctedLine.replacingOccurrences(of: "\"\"", with: substitute)
        var components = correctedLine.components(separatedBy: delimiter)

        var index = 0
        while index < components.count {
            let element = components[index]

            if index < components.count - 1 && startPartRegex.firstMatch(in: element, options: .anchored, range: element.fullRange) != nil {
                var elementsToMerge = [element]

                while middlePartRegex.firstMatch(in: components[index + 1], options: .anchored, range: components[index + 1].fullRange) != nil {
                    elementsToMerge.append(components[index + 1])
                    components.remove(at: index + 1)
                }

                if endPartRegex.firstMatch(in: components[index + 1], options: .anchored, range: components[index + 1].fullRange) != nil {
                    elementsToMerge.append(components[index + 1])
                    components.remove(at: index + 1)
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

    func reportFail() {
        if let failClosure = self.failClosure {
            callbacksDispatchQueue.async {
                failClosure()
            }
        }
    }

    func reportProgressIfNeeded(_ importedRecords: [T]) {
        if self.shouldReportProgress {
            self.lastProgressReport = Date()

            if let progressClosure = self.progressClosure {
                callbacksDispatchQueue.async {
                    progressClosure(importedRecords.count)
                }
            }
        }
    }

    func reportFinish(_ importedRecords: [T]) {
        if let finishClosure = self.finishClosure {
            callbacksDispatchQueue.async {
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
