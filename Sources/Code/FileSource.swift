//
//  FileSource.swift
//  CSVImporter
//
//  Created by Cihat Gündüz on 10.12.17.
//  Copyright © 2017 Flinesoft. All rights reserved.
//

import Foundation

class FileSource: Source {
    private let textFile: TextFile
    private let encoding: String.Encoding
    private var lineEnding: LineEnding

    init(textFile: TextFile, encoding: String.Encoding, lineEnding: LineEnding) {
        self.textFile = textFile
        self.encoding = encoding
        self.lineEnding = lineEnding
    }

    func forEach(_ closure: (String) -> Void) {
        if lineEnding == .unknown {
            lineEnding = lineEndingForFile()
        }

        guard let csvStreamReader = textFile.streamReader(lineEnding: lineEnding, chunkSize: chunkSize) else { return }
        csvStreamReader.forEach(closure)
    }

    /// Determines the line ending for the CSV file
    ///
    /// - Returns: the lineEnding for the CSV file or default of NL.
    private func lineEndingForFile() -> LineEnding {
        var lineEnding: LineEnding = .newLine
        if let fileHandle = textFile.handleForReading {
            if let data = (fileHandle.readData(ofLength: chunkSize) as NSData).mutableCopy() as? NSMutableData {
                if let contents = NSString(bytesNoCopy: data.mutableBytes, length: data.length, encoding: encoding.rawValue, freeWhenDone: false) {
                    if contents.contains(LineEnding.carriageReturnLineFeed.rawValue) {
                        lineEnding = .carriageReturnLineFeed
                    } else if contents.contains(LineEnding.newLine.rawValue) {
                        lineEnding = .newLine
                    } else if contents.contains(LineEnding.carriageReturn.rawValue) {
                        lineEnding = .carriageReturn
                    }
                }
            }
        }

        return lineEnding
    }
}
