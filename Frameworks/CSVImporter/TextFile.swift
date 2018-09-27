//
//  Created by Cihat Gündüz on 16.12.16.
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

// MARK: File Handle
extension TextFile {
    /// Returns a file handle for reading from `self`, or `nil` if `self`
    /// doesn't exist.
    var handleForReading: FileHandle? {
        return FileHandle(forReadingAtPath: path)
    }
}
