//
//  Created by Cihat Gündüz on 16.12.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//
//  Originally copied from https://github.com/nvzqz/FileKit/blob/feature-swift3/Sources/TextFile.swift
//

import Foundation

/// A class to read `TextFile` line by line.
class TextFileStreamReader {
    /// The text encoding.
    let encoding: String.Encoding

    /// The chunk size when reading.
    let chunkSize: Int

    /// Tells if the position is at the end of file.
    var atEOF: Bool = false

    let fileHandle: FileHandle
    let buffer: NSMutableData
    let delimData: Data

    // MARK: - Initialization
    /// - Parameter path:      the file path
    /// - Parameter lineEnding: the line ending delimiter (default: \n)
    /// - Parameter encoding: file encoding (default: NSUTF8StringEncoding)
    /// - Parameter chunkSize: size of buffer (default: 4096)
    init?(path: String, lineEnding: LineEnding, encoding: String.Encoding, chunkSize: Int) {
        self.chunkSize = chunkSize
        self.encoding = encoding

        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = lineEnding.rawValue.data(using: encoding),
            let buffer = NSMutableData(capacity: chunkSize)
        else {
            return nil
        }
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = buffer
    }

    // MARK: - Deinitialization
    deinit {
        self.close()
    }

    // MARK: - public methods
    /// - Returns: The next line, or nil on EOF.
    func nextLine() -> String? {
        guard !atEOF else { return nil }

        // Read data chunks from file until a line delimiter is found.
        var range = buffer.range(of: delimData, options: [], in: NSRange(location: 0, length: buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.isEmpty {
                // EOF or read error.
                atEOF = true
                if buffer.length > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = NSString(data: buffer as Data, encoding: encoding.rawValue)

                    buffer.length = 0
                    return line as String?
                }

                // No more lines.
                return nil
            }

            buffer.append(tmpData)
            range = buffer.range(of: delimData, options: [], in: NSRange(location: 0, length: buffer.length))
        }

        // Convert complete line (excluding the delimiter) to a string.
        let lineRange = NSRange(location: 0, length: range.location)
        let line = NSString(data: buffer.subdata(with: lineRange), encoding: encoding.rawValue)

        // Remove line (and the delimiter) from the buffer.
        let cleaningRange = NSRange(location: 0, length: range.location + range.length)
        buffer.replaceBytes(in: cleaningRange, withBytes: nil, length: 0)

        return line as String?
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() {
        fileHandle.closeFile()
    }
}

// Implement `SequenceType` for `TextFileStreamReader`
extension TextFileStreamReader: Sequence {
    /// - Returns: An iterator to be used for iterating over a `TextFileStreamReader` object.
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}
