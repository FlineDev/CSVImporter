//
//  TextFile.swift
//  CSVImporter
//
//  Created by Cihat Gündüz (Privat) on 16.12.16.
//  Copyright © 2016 Flinesoft. All rights reserved.
//
//  Originally copied from https://github.com/nvzqz/FileKit/blob/feature-swift3/Sources/TextFile.swift
//

import Foundation

/// A representation of a filesystem text file.
///
/// The data type is String.
class TextFile {
    /// The text file's string encoding.
    fileprivate var encoding: String.Encoding

    /// The file's filesystem path.
    fileprivate var path: String

    /// Initializes a text file from a path with an encoding.
    ///
    /// - Parameter path: The path to be created a text file from.
    /// - Parameter encoding: The encoding to be used for the text file.
    init(path: String, encoding: String.Encoding) {
        self.path = path
        self.encoding = encoding
    }
}

// MARK: Line Reader
extension TextFile {
    /// Provide a reader to read line by line.
    ///
    /// - Parameter delimiter: the line delimiter (default: \n)
    /// - Parameter chunkSize: size of buffer (default: 4096)
    ///
    /// - Returns: the `TextFileStreamReader`
    func streamReader(lineEnding: LineEnding, chunkSize: Int) -> TextFileStreamReader? {
        return TextFileStreamReader(path: self.path, lineEnding: lineEnding, encoding: encoding, chunkSize: chunkSize)
    }
}

/// A class to read `TextFile` line by line.
class TextFileStreamReader {
    /// The text encoding.
    fileprivate let encoding: String.Encoding

    /// The chunk size when reading.
    fileprivate let chunkSize: Int

    /// Tells if the position is at the end of file.
    fileprivate var atEOF: Bool = false

    fileprivate let fileHandle: FileHandle!
    fileprivate let buffer: NSMutableData!
    fileprivate let delimData: Data!

    // MARK: - Initialization
    /// - Parameter path:      the file path
    /// - Parameter lineEnding: the line ending delimiter (default: \n)
    /// - Parameter encoding: file encoding (default: NSUTF8StringEncoding)
    /// - Parameter chunkSize: size of buffer (default: 4096)
    fileprivate init?(path: String, lineEnding: LineEnding, encoding: String.Encoding, chunkSize: Int) {
        self.chunkSize = chunkSize
        self.encoding = encoding

        guard let fileHandle = FileHandle(forReadingAtPath: path), let delimData = lineEnding.rawValue.data(using: encoding),
            let buffer = NSMutableData(capacity: chunkSize) else {
                self.fileHandle = nil
                self.delimData = nil
                self.buffer = nil
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
    fileprivate func nextLine() -> String? {
        if atEOF { return nil }

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
    fileprivate func close() {
        fileHandle?.closeFile()
    }
}

// MARK: File Handle
extension TextFile {
    /// Returns a file handle for reading from `self`, or `nil` if `self`
    /// doesn't exist.
    var handleForReading: FileHandle? {
        return FileHandle(forReadingAtPath: path)
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
